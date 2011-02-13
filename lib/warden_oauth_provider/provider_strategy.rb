require 'oauth/request_proxy/rack_request'
require 'oauth/signature/plaintext'

require 'warden_oauth_provider/client_application'
require 'warden_oauth_provider/nonce'

module WardenOauthProvider
  
  class ProviderStrategy < Warden::Strategies::Base
    include OAuth::Helper
    
    def valid?
      http_authorization? and http_authorization =~ /^OAuth/
    end
    
    def authenticate!
      fail!("Invalid signature or nonce") and return if !verify_request

      case request.path
      when warden.config.oauth_request_token_path
        
        # Return a request token for the client application
        request_token = WardenOauthProvider::Token::Request.create!(:client_application => client_application, :callback_url => oauth_request.oauth_callback)
        custom! [200, {}, ["oauth_token=#{escape(request_token.token)}&oauth_token_secret=#{escape(request_token.secret)}&oauth_callback_confirmed=true"]]
      when warden.config.oauth_access_token_path

        # Exchange the access token and return it
        if access_token = (current_token && current_token.exchange!(oauth_request.oauth_verifier))
          custom! [200, {}, ["oauth_token=#{escape(access_token.token)}&oauth_token_secret=#{escape(access_token.secret)}"]]
        else
          fail!("Request token exchange failed")
        end
      else
        
        # Validate the current token as an access token and allow access to the resources
        if current_token and current_token.is_a?(WardenOauthProvider::Token::Access)
          success!(current_token.user)
        else
          fail!("Invalid access token")
        end          
      end
    end
    
  private
  
    def request
      @request ||= Rack::Request.new(env)
    end
    
    def oauth_request
      @oauth_request ||= OAuth::RequestProxy.proxy(request)
    end
    
    # Find the signature for the current request and match it with the information in the database.
    # Also adds the current client application and token to the environment
    def signature
      @signature ||= OAuth::Signature.build(oauth_request, :consumer => client_application, :token => current_token)
    end
    
    # Verify the request by checking the nonce and the signature
    def verify_request
      WardenOauthProvider::Nonce.remember(oauth_request.nonce, oauth_request.timestamp) && signature && signature.verify
    end
    
    # Returns the current token in the database, based on the token provided in the request
    def current_token
      return nil if oauth_request.token.nil? or client_application.nil?
      env['oauth.token'] ||= client_application.tokens.validated.find_by_token(oauth_request.token)
    end
    
    # Returns the current client application, based on the consumer key in the request
    def client_application
      env['oauth.client_application'] ||= WardenOauthProvider::ClientApplication.find_by_key(oauth_request.consumer_key)
    end
    
    def warden
      env['warden']
    end
    
    def http_authorization
      request.env['HTTP_AUTHORIZATION']   ||
      request.env['X-HTTP_AUTHORIZATION'] ||
      request.env['X_HTTP_AUTHORIZATION'] ||
      request.env['REDIRECT_X_HTTP_AUTHORIZATION']
    end
    alias :http_authorization? :http_authorization
    
  end
  
end
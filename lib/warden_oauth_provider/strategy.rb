require 'oauth/request_proxy/rack_request'
require 'oauth/signature/plaintext'

require 'warden_oauth_provider/client_application'
require 'warden_oauth_provider/request_token'
require 'warden_oauth_provider/access_token'

module WardenOauthProvider
  
  class Strategy < Warden::Strategies::Base
    include OAuth::Helper
    
    def valid?
      http_authorization? and http_authorization =~ /^OAuth/
    end
    
    def authenticate!      
      fail!("Invalid signature or nonce") and return if !verify_request

      case request.path
      when warden.config.oauth_request_token_path
        
        # Return a request token for the client application
        request_token = WardenOauthProvider::RequestToken.create(:client_application => client_application, :callback_url => oauth_request.oauth_callback)
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
        if current_token and current_token.is_a?(WardenOauthProvider::AccessToken)
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
      @signature ||= OAuth::Signature.build(request) do |request_proxy|
        env['oauth.client_application'] = WardenOauthProvider::ClientApplication.find_by_key(request_proxy.consumer_key)
        return nil unless env['oauth.client_application']
        
        if request_proxy.token
          env['oauth.token'] = env['oauth.client_application'].tokens.validated.find_by_token(request_proxy.token)
          secret = env['oauth.token'].secret if env['oauth.token']
        end
        
        [secret, env['oauth.client_application'].secret]
      end
    end
    
    def verify_request
      signature && signature.verify # && Nonce.check!!
    end
    
    def current_token
      env['oauth.token']
    end
    
    def client_application
      env['oauth.client_application']
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
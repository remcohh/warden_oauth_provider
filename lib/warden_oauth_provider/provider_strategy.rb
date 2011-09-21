require 'oauth/request_proxy/rack_request'
require 'oauth/signature/plaintext'

require 'warden_oauth_provider/client_application'
require 'warden_oauth_provider/nonce'

module WardenOauthProvider
  
  class ProviderStrategy < Warden::Strategies::Base
    include OAuth::Helper
    
    def valid?
      oauth_request.oauth_parameters.length > 1
    end
    
    def authenticate!
      fail!("Invalid signature or nonce") and return if !verify_request

      case request.path
      when warden.config.oauth_request_token_path
        
        # Return a request token for the client application
        request_token = WardenOauthProvider::Token::Request.create!(:client_application => client_application, :callback_url => oauth_request.oauth_callback)
        custom! [200, { 'Content-Type' => 'text/html' }, ["oauth_token=#{escape(request_token.token)}&oauth_token_secret=#{escape(request_token.secret)}&oauth_callback_confirmed=true"]]
      when warden.config.oauth_access_token_path
        
        if xauth_params? and xauth_mode == 'client_auth'
          
          # Get the user authentication proc from the settings
          user_authentication = warden.config.xauth_user || Proc.new { |env, username, password| nil }
          
          # Create an access token when the client application has xauth enabled and the user can be authenticated
          if client_application.xauth_enabled? and (user = user_authentication.call(env, xauth_username, xauth_password))
            access_token = WardenOauthProvider::Token::Access.create!(:client_application => client_application, :user => user)
          elsif user.nil?
            fail!("Authentication failed")
          else
            fail!("xauth not allowed for client application")
          end
        else 

          # Exchange the access token and return it
          if !(access_token = (current_token && current_token.exchange!(oauth_request.oauth_verifier)))
            fail!("Request token exchange failed")
          end
        end
        
        if access_token
          custom! [200, { 'Content-Type' => 'text/html' }, ["oauth_token=#{escape(access_token.token)}&oauth_token_secret=#{escape(access_token.secret)}"]]        
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
    
  protected
  
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
    
    def xauth_params?
      request.post? and !xauth_username.nil? and !xauth_password.nil?
    end
    
    def xauth_mode
      request.params['x_auth_mode']
    end
    
    def xauth_username
      request.params['x_auth_username']
    end

    def xauth_password
      request.params['x_auth_password']
    end
        
  end
  
end
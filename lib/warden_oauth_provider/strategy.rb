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
      if request_token_path?
        request_token_response
      elsif access_token_path?
        access_token_response
      else
        access_token = find_token
        if access_token and access_token.is_a?(WardenOauthProvider::AccessToken)
          success!(access_token.user)
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
  
    def request_token_path?
      request.path =~  /^\/oauth\/request_token/
    end
    
    def access_token_path?
      request.path =~ /^\/oauth\/access_token/
    end
  
    def request_token_response
      client_application = find_client_application
      
      if client_application
        request_token = WardenOauthProvider::RequestToken.create(:client_application => client_application, :callback_url => oauth_request.oauth_callback)
        custom! [200, {}, ["oauth_token=#{escape(request_token.token)}&oauth_token_secret=#{escape(request_token.secret)}&oauth_callback_confirmed=true"]]
      else
        fail!("Unknown client application")
      end
    end
    
    def access_token_response
      request_token = find_token
      access_token = request_token && request_token.exchange!(oauth_request.oauth_verifier)
      
      if access_token
        custom! [200, {}, ["oauth_token=#{escape(access_token.token)}&oauth_token_secret=#{escape(access_token.secret)}"]]
      else
        fail!("Request token exchange failed")
      end
    end
    
    # Finds the client application and adds it to the environment
    def find_client_application
      signature = OAuth::Signature.build(request) do |request_proxy|
        if @client_application = WardenOauthProvider::ClientApplication.find_by_key(request_proxy.consumer_key)
          [nil, @client_application.secret]
        else
          [nil, nil]
        end
      end
      signature.verify
      @client_application
    end
    
    def find_token
      signature = OAuth::Signature.build(request) do |request_proxy|
        if @token = WardenOauthProvider::OauthToken.find_by_token(request_proxy.token) and @token.authorized?
          [@token.secret, @token.client_application.secret]
        else
          [nil, nil]
        end
      end
      signature.verify
      @token
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
require 'oauth/request_proxy/rack_request'
require 'oauth/signature/plaintext'
require 'warden_oauth_provider/client_application'
require 'warden_oauth_provider/request_token'

module WardenOauthProvider
  
  class Strategy < Warden::Strategies::Base
    
    include OAuth::Helper
    
    def valid?
      http_authorization? and http_authorization =~ /^OAuth/
    end
    
    def authenticate!
      if request_token_path?
        request_token_response
      end
    end
    
  private
  
    def request
      @request ||= Rack::Request.new(env)
    end
  
    def request_token_path?
      @request.path =~  /^\/oauth\/request_token/
    end
  
    def request_token_response
      @signature = OAuth::Signature.build(request) do |request_proxy|
        client_application = WardenOauthProvider::ClientApplication.find_by_key(request_proxy.consumer_key)
        if client_application
          client_application.token_callback_url = request_proxy.oauth_callback if request_proxy.oauth_callback
          env['oauth.client_application'] = client_application
          [nil, client_application.secret]
        else
          [nil, nil]
        end
      end
      
      if env['oauth.client_application']
        request_token = WardenOauthProvider::RequestToken.create(:client_application => env['oauth.client_application'], :callback_url => env['oauth.client_application'].token_callback_url)
        custom! [200, {}, ["oauth_token=#{escape(request_token.token)}&oauth_token_secret=#{escape(request_token.secret)}&oauth_callback_confirmed=true"]]
      else
        fail!("Unknown client application")
      end
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
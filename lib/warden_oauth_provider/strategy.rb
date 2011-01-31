require 'oauth/request_proxy/rack_request'
require 'oauth/signature/plaintext'
require 'warden_oauth_provider/client_application'

module WardenOauthProvider
  
  class Strategy < Warden::Strategies::Base
    
    def valid?
      http_authorization? and http_authorization =~ /^OAuth/
    end
    
    def authenticate!
      @rack_request = Rack::Request.new(env)
      
      if @rack_request.path =~ /^\/oauth\/request_token/
        @signature = OAuth::Signature.build(@rack_request) do |request_proxy|
          client_application = WardenOauthProvider::ClientApplication.find_by_key(request_proxy.consumer_key)
          client_application.token_callback_url = request_proxy.oauth_callback if request_proxy.oauth_callback
          env['oauth.client_application'] = client_application
          [nil, client_application.secret]
        end
        
        custom! [200, {}, "oauth_token=hh5s93j4hdidpola&oauth_token_secret=hdhd0244k9j7ao03&oauth_callback_confirmed=true"]
      end
    end
    
  private
  
    def http_authorization
      request.env['HTTP_AUTHORIZATION']   ||
      request.env['X-HTTP_AUTHORIZATION'] ||
      request.env['X_HTTP_AUTHORIZATION'] ||
      request.env['REDIRECT_X_HTTP_AUTHORIZATION']
    end
    alias :http_authorization? :http_authorization
    
    
  end
  
end
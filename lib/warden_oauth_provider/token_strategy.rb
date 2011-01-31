module WardenOauthProvider
  class TokenStrategy < Warden::Strategies::Base
    
    def valid?
      true
    end
    
    def authenticate!
      request_token = WardenOauthProvider::RequestToken.find_by_token(request.params["oauth_token"])
      
      if request_token.invalidated?
        fail!
      else
        request_token.authorize!(user)
        redirect_url = URI.parse(request_token.oob? ? request_token.client_application.callback_url : request_token.callback_url)

        redirect_url.query ||= ""
        redirect_url.query += "&" unless redirect_url.query.blank?
        redirect_url.query += "oauth_token=#{request_token.token}&oauth_verifier=#{request_token.verifier}"
        env['oauth.redirect_url'] = redirect_url.to_s
        success!(request_token)
      end
    end
    
  private

    def request
      @request ||= Rack::Request.new(env)
    end  
    
  end
end
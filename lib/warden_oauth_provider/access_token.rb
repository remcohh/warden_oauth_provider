require 'warden_oauth_provider/oauth_token'

module WardenOauthProvider
  class AccessToken < OauthToken
    validates_presence_of :user, :secret
    
    before_create do
      self.authorized_at = Time.now
    end    
  end
end
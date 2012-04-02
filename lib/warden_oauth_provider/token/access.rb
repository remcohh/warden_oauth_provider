module WardenOauthProvider
  module Token
    class Access < Base
      validates_presence_of :user, :secret
      
      attr_accessible :client_application, :user
    
      before_create do
        self.authorized_at = Time.now
      end
    end
  end
end
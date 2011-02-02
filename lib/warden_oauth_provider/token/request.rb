module WardenOauthProvider
  module Token
    class Request < Base

      def authorize!(user)
        return false if authorized? or user.nil?
        self.user          = user
        self.authorized_at = Time.now
        self.verifier      = OAuth::Helper.generate_key(20)[0,20]
        self.save
      end

      def exchange!(verifier)
        return false unless authorized?
        return false if self.verifier != verifier
        self::class.transaction do
          access_token = WardenOauthProvider::Token::Access.create!(:user => user, :client_application => client_application)
          invalidate!
          access_token
        end
      end

      # TODO: check what the requirements for OOB are
      def oob?
        self.callback_url.blank? || self.callback_url == 'oob'
      end
    end
  end
end
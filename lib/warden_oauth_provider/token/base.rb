module WardenOauthProvider
  module Token
    class Base < ActiveRecord::Base
      self.table_name = "oauth_tokens"
      
      belongs_to :client_application
      belongs_to :user
      
      validates_uniqueness_of :token
      validates_presence_of :client_application, :token
      
      attr_accessible :client_application, :client_application_id

      scope :validated, ->{ where("authorized_at IS NOT NULL and invalidated_at IS NULL")}

      before_validation(:on => :create) do
        self.token = OAuth::Helper.generate_key(40)[0,40]
        self.secret = OAuth::Helper.generate_key(40)[0,40]
      end

      def invalidated?
        invalidated_at != nil
      end

      def invalidate!
        update_attribute(:invalidated_at, Time.now)
      end

      def authorized?
        authorized_at != nil && !invalidated?
      end
    end
  end
end

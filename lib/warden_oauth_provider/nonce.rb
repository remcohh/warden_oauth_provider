module WardenOauthProvider
  class Nonce < ActiveRecord::Base
    self.table_name = "oauth_nonces"
    
    validates_presence_of :nonce, :timestamp
    validates_uniqueness_of :nonce, :scope => :timestamp
  
    # Remembers a nonce and it's associated timestamp. It returns false if it has already been used
    def self.remember(nonce, timestamp)
      Nonce.create!(:nonce => nonce, :timestamp => timestamp)
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
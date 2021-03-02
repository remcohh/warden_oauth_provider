module WardenOauthProvider
  class ClientApplication < ActiveRecord::Base

    has_many :tokens, :class_name => "WardenOauthProvider::Token::Base", :dependent => :destroy
    has_many :access_tokens
    has_many :oauth_tokens
    
    validates_presence_of :name, :url, :key, :secret
    validates_uniqueness_of :key

    before_validation(:on => :create) do
      self.key    = OAuth::Helper.generate_key(40)[0,40]
      self.secret = OAuth::Helper.generate_key(40)[0,40]
    end

    validates_format_of :url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
    validates_format_of :support_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true
    validates_format_of :callback_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true
    
    #attr_accessible :name, :url, :support_url, :callback_url
    
  end
end
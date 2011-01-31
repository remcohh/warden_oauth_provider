module WardenOauthProvider
  class ClientApplication < ActiveRecord::Base

    # has_many :tokens, :class_name => "OauthToken"
    # has_many :access_tokens
    # has_many :oauth2_verifiers
    # has_many :oauth_tokens
    validates_presence_of :name, :url, :key, :secret
    validates_uniqueness_of :key

    before_validation(:on => :create) do
      self.key    = OAuth::Helper.generate_key(40)[0,40]
      self.secret = OAuth::Helper.generate_key(40)[0,40]
    end

    validates_format_of :url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i
    validates_format_of :support_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true
    validates_format_of :callback_url, :with => /\Ahttp(s?):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i, :allow_blank=>true

    attr_accessor :token_callback_url

    def self.find_token(token_key)
      token = WardenOauthProvider::OauthToken.find_by_token(token_key, :include => :client_application)
      if token && token.authorized?
        token
      else
        nil
      end
    end
  end
end
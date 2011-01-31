require 'warden'
require 'oauth'
require 'active_record'
require 'warden_oauth_provider/strategy'
require 'warden_oauth_provider/token_strategy'

Warden::Strategies.add(:oauth, WardenOauthProvider::Strategy)
Warden::Strategies.add(:oauth_token, WardenOauthProvider::TokenStrategy)

module Warden
  class Config
    hash_accessor :oauth_request_token_path, :oauth_access_token_path
  end
end
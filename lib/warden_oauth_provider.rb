require 'warden'
require 'oauth'
require 'active_record'

require 'warden_oauth_provider/provider_strategy'
require 'warden_oauth_provider/token_strategy'

require 'warden_oauth_provider/token/base'
require 'warden_oauth_provider/token/request'
require 'warden_oauth_provider/token/access'

Warden::Strategies.add(:oauth_provider, WardenOauthProvider::ProviderStrategy)
Warden::Strategies.add(:oauth_token, WardenOauthProvider::TokenStrategy)

module Warden
  class Config
    hash_accessor :oauth_request_token_path, :oauth_access_token_path, :xauth_user
  end
end
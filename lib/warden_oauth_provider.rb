require 'warden'
require 'oauth'
require 'active_record'
require 'warden_oauth_provider/strategy'
require 'warden_oauth_provider/token_strategy'

Warden::Strategies.add(:oauth, WardenOauthProvider::Strategy)
Warden::Strategies.add(:oauth_token, WardenOauthProvider::TokenStrategy)
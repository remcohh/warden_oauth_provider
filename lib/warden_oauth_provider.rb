require 'warden'
require 'oauth'
require 'active_record'
require 'warden_oauth_provider/strategy'

Warden::Strategies.add(:oauth, WardenOauthProvider::Strategy)
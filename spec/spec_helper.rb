require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/mocks'
require 'warden_oauth_provider'
require 'rack'
require 'sqlite3'
require 'factory_girl'
require 'logger'

require 'helpers/factories'
require 'helpers/request_helper'

RSpec.configure do |config|
  config.mock_with :rspec
  
  config.include(RequestHelper)
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.logger = Logger.new("test.log")
ActiveRecord::Base.mass_assignment_sanitizer = :strict

ActiveRecord::Schema.define do
  create_table :client_applications, :force => true do |t|
    t.string :name
    t.string :url
    t.string :support_url
    t.string :callback_url
    t.string :key, :limit => 40
    t.string :secret, :limit => 40
    t.integer :user_id
    t.boolean :xauth_enabled, :default => false

    t.timestamps
  end
  add_index :client_applications, :key, :unique => true
  
  create_table :oauth_tokens, :force => true do |t|
    t.integer :user_id
    t.string :type, :limit => 20
    t.integer :client_application_id
    t.string :token, :limit => 40
    t.string :secret, :limit => 40
    t.string :callback_url
    t.string :verifier, :limit => 20
    t.string :scope
    t.timestamp :authorized_at, :invalidated_at, :valid_to
    t.timestamps
  end
  add_index :oauth_tokens, :token, :unique => true
  
  create_table :oauth_nonces do |t|
    t.string :nonce
    t.integer :timestamp

    t.timestamps
  end
  add_index :oauth_nonces,[:nonce, :timestamp], :unique
  
  create_table :users, :force => true do |t|
    t.string :name
    t.string :password
  end
end

class User < ActiveRecord::Base
end
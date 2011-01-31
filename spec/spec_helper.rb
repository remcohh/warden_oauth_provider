require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rspec/mocks'
require 'warden_oauth_provider'
require 'rack'
require 'sqlite3'
require 'factory_girl'

require 'helpers/factories'
require 'helpers/request_helper'

RSpec.configure do |config|
  config.mock_with :rspec
  
  config.include(RequestHelper)
end

ENV['RAILS_ENV'] = 'test'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :client_applications, :force => true do |t|
    t.string :name
    t.string :url
    t.string :support_url
    t.string :callback_url
    t.string :key, :limit => 40
    t.string :secret, :limit => 40
    t.integer :user_id

    t.timestamps
  end
  
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
  
  create_table :users, :force => true do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
end
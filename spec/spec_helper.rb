require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'warden_oauth_provider'
require 'rack'
require 'sqlite3'

require 'request_helper'

RSpec.configure do |config|
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
end
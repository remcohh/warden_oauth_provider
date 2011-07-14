require 'rails/generators'
require 'rails/generators/controller'

class WardenOauthProvider::ControllerGenerator < Rails::Generators::Base
  
  include Rails::Generators::ControllerGenerator
  
  def self.source_root
     @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def add_routes
    
  end
  
end
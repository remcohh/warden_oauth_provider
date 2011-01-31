module RequestHelper
  
  def env_with_params(path, params = {}, env = {})
    method = params.delete(:method) || "GET"
    env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => "#{method}" }.merge(env)
    Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}", env)
  end
  
  def setup_rack(app = nil, opts = {})
    app ||= default_app
    opts[:failure_app]         ||= failure_app
    opts[:default_strategies]  ||= [:oauth]
    
    Rack::Builder.new do
      use RequestHelper::Session
      use Warden::Manager, opts
      run app
    end    
  end
  
  def default_app
    lambda do |env|
      env['warden'].authenticate!
      [200, {"Content-Type" => "text/plain"}, ["Very secret resource!"]]
    end
  end
  
  def failure_app
    lambda do |env|
      [401, {"Content-Type" => "text/plain"}, ["You Fail!"]]
    end
  end
  
  
  class Session
    attr_accessor :app
    def initialize(app,configs = {})
      @app = app
    end

    def call(e)
      e['rack.session'] ||= {}
      @app.call(e)
    end
  end # session
  
end
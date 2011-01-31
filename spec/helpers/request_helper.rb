module RequestHelper
  
  def env_with_params(path, params = {}, env = {})
    method = params.delete(:method) || "GET"
    env = { 'HTTP_VERSION' => '1.1', 'REQUEST_METHOD' => "#{method}" }.merge(env)
    Rack::MockRequest.env_for("#{path}?#{Rack::Utils.build_query(params)}", env)
  end
  
  def oauth_header(params)
    "OAuth #{params.collect { |k,v| "#{k}=\"#{v}\""}.join(", ") }"
  end
  
  def setup_rack(app = nil, opts = {})
    app ||= default_app
    
    Warden::Strategies.add(:success) do
      def authenticate!
        success!("edwin")
      end
    end
    
    opts[:failure_app]         ||= failure_app
    opts[:default_strategies]  ||= [:oauth, :success]
    
    Rack::Builder.new do
      use RequestHelper::Session
      use Warden::Manager, opts
      run app
    end    
  end
  
  def default_app
    lambda do |env|
      env['warden'].authenticate!
      request = Rack::Request.new(env)
      if request.path =~ /^\/oauth\/authorize/
        if env['warden'].authenticate?(:oauth_token, :scope => :oauth_token)
          [302, {"Location" => env['oauth.redirect_url']}, []]
        else
          [200, {"Content-Type" => "text/plain"}, ["You have not authorized"]]
        end
      else
        [200, {"Content-Type" => "text/plain"}, ["Very secret resource!"]]
      end
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
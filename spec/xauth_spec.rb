require 'spec_helper'

describe 'xauth' do
  
  context "success" do
    before(:all) do
      @user = Factory(:user)
      @client_application = Factory.create(:client_application, :xauth_enabled => true)
    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26"
      })
      
      xauth_params = {
        :x_auth_mode => "client_auth",
        :x_auth_username => "John",
        :x_auth_password => "testtest"
      }
    
      env = env_with_params("/oauth/access_token", xauth_params.merge({ :method => "POST" }), {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @oauth_response = Hash[*@response.last.first.split("&").collect { |v| v.split("=") }.flatten]
    end
  
    it "should have an oauth access token" do
      @oauth_response.keys.should include("oauth_token")
      @oauth_response["oauth_token"].should_not be_nil
    end
  
    it "should have an oauth access token secret" do
      @oauth_response.keys.should include("oauth_token_secret")
      @oauth_response["oauth_token_secret"].should_not be_nil
    end
  
    it "should have stored an access token with the token and secret" do
      WardenOauthProvider::Token::Access.where(:token => @oauth_response["oauth_token"], :secret => @oauth_response["oauth_token_secret"]).count.should == 1
    end
  end
  
  context "Failure" do
    
    before(:all) do
      @user = Factory(:user)
      @client_application = Factory.create(:client_application, :xauth_enabled => true)
    end
    
    it "should response with a 401 if the client application is unknown" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => "somerandomstring",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26"
      })
      
      xauth_params = {
        :x_auth_mode => "client_auth",
        :x_auth_username => "John",
        :x_auth_password => "testtest"
      }
      
      env = env_with_params("/oauth/access_token", xauth_params.merge({ :method => "POST" }), {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
    
    it "should response with a 401 if the credentials are invalid" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26"
      })
      
      xauth_params = {
        :x_auth_mode => "client_auth",
        :x_auth_username => "John",
        :x_auth_password => "invalidpassword"
      }
      
      env = env_with_params("/oauth/access_token", xauth_params.merge({ :method => "POST" }), {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
    
    it "should response with a 401 if the client application is not authorized for xauth" do
      @client_application.update_attribute(:xauth_enabled, false)
      
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26"
      })
      
      xauth_params = {
        :x_auth_mode => "client_auth",
        :x_auth_username => "John",
        :x_auth_password => "testtest"
      }
      
      env = env_with_params("/oauth/access_token", xauth_params.merge({ :method => "POST" }), {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
    
    it "should response with a 401 if no xauth user proc is given" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26"
      })
      
      xauth_params = {
        :x_auth_mode => "client_auth",
        :x_auth_username => "John",
        :x_auth_password => "testtest"
      }
      
      env = env_with_params("/oauth/access_token", xauth_params.merge({ :method => "POST" }), {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack(nil, :xauth_user => nil).call(env)
      @response.first.should == 401
    end
  end
  
end
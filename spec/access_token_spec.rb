require 'spec_helper'

describe "Access token" do

  context "Success" do

    before(:all) do
      @user = Factory(:user)
      @client_application = Factory.create(:client_application)
      @request_token = Factory.create(:request_token, :client_application => @client_application)
      @request_token.authorize!(@user)
      
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @request_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier,
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret
      })
      
      env = env_with_params("/oauth/access_token", {}, {
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
      @client_application = Factory.create(:client_application)
      @request_token = Factory.create(:request_token, :client_application => @client_application)
      @request_token.authorize!(@user)
    end
    
    it "should response with a 401 if the second request contains the same nonce" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @request_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier,
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret
      })
      env1 = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      env2 = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response1 = setup_rack.call(env1)
      @response2 = setup_rack.call(env2)
      @response2.first.should == 401
    end
    
    it "should response with a 401 if the consumer key is invalid" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key + "invalid",
        :oauth_token => @request_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier,
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret
      })
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should response with a 401 if the token is invalid" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @request_token.token + "invalid",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier,
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret
      })
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should response with a 401 if the verifier is invalid" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @request_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier + "invalid",
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret
      })
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should response with a 401 if the signature is invalid" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @request_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier,
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret + "invalid"
      })
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should response with a 401 if consumer key or signature are invalid" do    
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key + "invalid",
        :oauth_token => @request_token.token + "invalid",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_verifier => @request_token.verifier + "invalid",
        :oauth_signature => @client_application.secret + "%26" + @request_token.secret + "invalid"
      })
      
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
  end  
end

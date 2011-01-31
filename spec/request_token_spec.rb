require 'spec_helper'

describe "Request token" do
  
  context "Success" do
    
    before(:all) do
      @client_application = Factory.create(:client_application)
      auth_signature = @client_application.secret + "%26"
      auth_str = sprintf('OAuth realm="MoneyBird", oauth_consumer_key="%s", oauth_signature_method="PLAINTEXT", oauth_timestamp="%d", oauth_nonce="%f", oauth_callback="oob", oauth_signature="%s"', @client_application.key, Time.now.to_i, Time.now.to_f, @client_application.secret)
      
      env = env_with_params("/oauth/request_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      puts @response.inspect
      @oauth_response = Hash[*@response.last.first.split("&").collect { |v| v.split("=") }.flatten]
    end
    
    it "should have an oauth token" do
      @oauth_response.keys.should include("oauth_token")
      @oauth_response["oauth_token"].should_not be_nil
      @oauth_token = @oauth_response["oauth_token"]
    end
    
    it "should have an oauth token secret" do
      @oauth_response.keys.should include("oauth_token_secret")
      @oauth_response["oauth_token_secret"].should_not be_nil
      @oauth_token_secret = @oauth_response["oauth_token_secret"]
    end
    
    it "should have an oauth callback confirmed header" do
      @oauth_response.keys.should include("oauth_callback_confirmed")
      @oauth_response["oauth_callback_confirmed"].should == "true"
    end
    
    it "should have created a new request token in the database" do
      WardenOauthProvider::RequestToken.where(:token => @oauth_response["oauth_token"], :secret => @oauth_response["oauth_token_secret"]).count.should == 1
    end
    
  end
  
  context "Failure" do
    it "should response with a 401 if consumer key or signature are invalid" do
      
    end
  end
  
end

describe "Authorize" do
  
  context "Success" do
    
    before(:all) do
      url = sprintf("/oauth/authorize?oauth_token=%s&authorize=1", @oauth_token)
      
      env = env_with_params(url, {}, {
        "HTTP_AUTHORIZATION" => auth_str
        # Basic authen
      })
      @response = setup_rack.call(env)
      @oauth_response = Hash[*@response.last.first.split("&").collect { |v| v.split("=") }.flatten]
    end
    
    it "should have an oauth token" do
      @oauth_response.keys.should include("oauth_token")
      @oauth_response["oauth_token"].should_not be_nil
      @oauth_token = @oauth_response["oauth_token"]
    end
    
    it "should have an oauth verifier" do
      @oauth_response.keys.should include("oauth_token_secret")
      @oauth_response["oauth_token_secret"].should_not be_nil
      @oauth_token_secret = @oauth_response["oauth_token_secret"]
    end
    
  end
  
  context "Failure" do
    it "should response with a 401 if consumer key or signature are invalid"
  end
  
end

describe "Access token" do

  context "Success" do

    before(:all) do
      auth_key = "1234"
      auth_secret = "abcd"
      auth_signature = auth_secret + "%26" + @oauth_token_secret
      auth_str = sprintf('OAuth realm="MoneyBird", oauth_consumer_key="%s", oauth_token="%s", oauth_signature_method="PLAINTEXT", oauth_timestamp="%d", oauth_nonce="%f", oauth_verifier="%s", oauth_signature="%s"', auth_key, @oauth_token, Time.now.to_i, Time.now.to_f, @oauth_verifier, auth_signature)
      
      env = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @oauth_response = Hash[*@response.last.first.split("&").collect { |v| v.split("=") }.flatten]
    end
    
    it "should have an oauth token" do
      @oauth_response.keys.should include("oauth_token")
      @oauth_response["oauth_token"].should_not be_nil
    end
    
    it "should have an oauth token secret" do
      @oauth_response.keys.should include("oauth_token_secret")
      @oauth_response["oauth_token_secret"].should_not be_nil
    end

  end
  
  context "Failure" do
    it "should response with a 401 if consumer key or signature are invalid"
  end
  
end

require 'spec_helper'

describe "Request token" do
  
  context "Success" do
    
    before(:all) do
      @client_application = Factory.create(:client_application)
      
      auth_str = oauth_header({
        :realm                  => "MoneyBird",
        :oauth_consumer_key     => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp        => Time.now.to_i,
        :oauth_nonce            => Time.now.to_f,
        :oauth_callback         => "oob",
        :oauth_signature        => @client_application.secret + "%26"
      })
      
      env = env_with_params("/oauth/request_token", {}, {
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
    
    it "should have an oauth callback confirmed header" do
      @oauth_response.keys.should include("oauth_callback_confirmed")
      @oauth_response["oauth_callback_confirmed"].should == "true"
    end
    
    it "should have created a new request token in the database" do
      WardenOauthProvider::Token::Request.where(:token => @oauth_response["oauth_token"], :secret => @oauth_response["oauth_token_secret"]).count.should == 1
    end
    
  end
  
  context "Failure" do
    it "should response with a 401 if consumer key or signature are invalid" do
      auth_str = oauth_header({
        :realm                  => "MoneyBird",
        :oauth_consumer_key     => "123456789",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp        => Time.now.to_i,
        :oauth_nonce            => Time.now.to_f,
        :oauth_callback         => "oob",
        :oauth_signature        => "testsignature"
      })
      
      env = env_with_params("/oauth/request_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
  end
  
end




require 'spec_helper'

describe "Request token" do
  
  context "Success" do
    
    before(:all) do
      auth_key = "1234"
      auth_secret = "abcd"
      auth_signature = auth_secret + "%26"
      auth_str = sprintf('OAuth realm="MoneyBird", oauth_consumer_key="%s", oauth_signature_method="PLAINTEXT", oauth_timestamp="%d", oauth_nonce="%f", oauth_callback="oob", oauth_signature="%s"', auth_key, Time.now.to_i, Time.now.to_f, auth_signature)
      
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
    
    it "should have an oauth secret" do
      @oauth_response.keys.should include("oauth_token_secret")
      @oauth_response["oauth_token_secret"].should_not be_nil
    end
    
    it "should have an oauth callback confirmed header" do
      @oauth_response.keys.should include("oauth_callback_confirmed")
      @oauth_response["oauth_callback_confirmed"].should == "true"
    end
    
  end
  
  context "Failure" do
    it "should response with a 401 if consumer key or signature are invalid"
  end
  
end
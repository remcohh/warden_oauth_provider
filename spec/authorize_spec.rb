require 'spec_helper'

describe "Authorize" do
  
  context "Success" do
    
    before(:all) do
      @request_token = Factory.create(:request_token, :client_application => Factory.create(:client_application))
      env = env_with_params("/oauth/authorize", {:oauth_token => @request_token.token, :username => "John", :password => "testtest"}, {})
      @response = setup_rack.call(env)
      @location = URI.parse(@response[1]["Location"])
      @oauth_response = Hash[*@location.query.split("&").collect { |v| v.split("=") }.flatten]
      @response.first.should == 302
    end
    
    it "should have an oauth token" do
      @oauth_response.keys.should include("oauth_token")
      @oauth_response["oauth_token"].should == @request_token.token
    end
    
    it "should have an oauth verifier" do
      @oauth_response.keys.should include("oauth_verifier")
      @oauth_response["oauth_verifier"].should_not be_nil
    end
    
    it "should have stored the oauth verifier in the database" do
      WardenOauthProvider::Token::Request.where(:token => @oauth_response["oauth_token"], :verifier => @oauth_response["oauth_verifier"]).count.should == 1
    end
    
  end
  
  context "Failure" do
    it "should response with a 401 if the token is invalidated" do
      @request_token = Factory.create(:request_token, :client_application => Factory.create(:client_application))
      @request_token.invalidate!
      
      env = env_with_params("/oauth/authorize", {:oauth_token => @request_token.token, :username => "John", :password => "testtest"}, {})
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
  end
  
end
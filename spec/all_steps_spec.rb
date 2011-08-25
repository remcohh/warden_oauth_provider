require 'spec_helper'

describe "OAuth all steps" do

  context "Success" do

    before(:all) do
      @client_application = Factory.create(:client_application)
      @user = Factory(:user)
    end

    it "should succeed all oauth steps" do
      
      # Step 1 - Request token
      auth_str_step1 = oauth_header({
        :realm                  => "MoneyBird",
        :oauth_consumer_key     => @client_application.key,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp        => Time.now.to_i+1,
        :oauth_nonce            => Time.now.to_f+1,
        :oauth_callback         => "oob",
        :oauth_signature        => @client_application.secret + "%26"
      })
      env_step1 = env_with_params("/oauth/request_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str_step1
      })
      response = setup_rack.call(env_step1)
      response.first.should == 200
      oauth_response = Hash[*response.last.first.split("&").collect { |v| v.split("=") }.flatten]
      oauth_request_token = oauth_response["oauth_token"]
      oauth_request_token_secret = oauth_response["oauth_token_secret"]
      
      # Step 2 - Authorize
      req = WardenOauthProvider::Token::Request.find_by_token(oauth_request_token)
      env_step2 = env_with_params("/oauth/authorize", {:oauth_token => oauth_request_token, :username => "John", :password => "testtest"}, {})
      response = setup_rack.call(env_step2)
      response.first.should == 302
      location = URI.parse(response[1]["Location"])
      oauth_response = Hash[*location.query.split("&").collect { |v| v.split("=") }.flatten]
      oauth_verifier = oauth_response["oauth_verifier"]
      
      # Step 3 - Access token
      auth_str_step3 = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => oauth_request_token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i+2,
        :oauth_nonce => Time.now.to_f+2,
        :oauth_verifier => oauth_verifier,
        :oauth_signature => @client_application.secret + "%26" + oauth_request_token_secret
      })
      env_step3 = env_with_params("/oauth/access_token", {}, {
        "HTTP_AUTHORIZATION" => auth_str_step3
      })
      response = setup_rack.call(env_step3)
      response.first.should == 200
      oauth_response = Hash[*response.last.first.split("&").collect { |v| v.split("=") }.flatten]
      oauth_access_token = oauth_response["oauth_token"]
      oauth_access_token_secret = oauth_response["oauth_token_secret"]
      
      # Step 4 - App request with access token
      auth_str_step4 = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => oauth_access_token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i+3,
        :oauth_nonce => Time.now.to_f+3,
        :oauth_signature => @client_application.secret + "%26" + oauth_access_token_secret
      })
      env_step4 = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str_step4
      })
      response = setup_rack.call(env_step4)
      response.first.should == 200      
    end    
  end
end

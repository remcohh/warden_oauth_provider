require 'spec_helper'

describe "OAuth request" do

  context "Success" do

    before(:all) do
      @user = Factory(:user)
      @client_application = Factory.create(:client_application)
      @access_token = Factory.create(:access_token, :user => @user, :client_application => @client_application)
    end

    it "should allow to access very secret resources" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @access_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 200
    end
    
  end
  
  context "Failure" do
    
    before(:all) do
      @user = Factory(:user)
      @client_application = Factory.create(:client_application)
      @access_token = Factory.create(:access_token, :user => @user, :client_application => @client_application)
    end

    it "should not allow to access very secret resources if the second request contains the same nonce" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @access_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret
      })
      env1 = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      env2 = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      
      @response1 = setup_rack.call(env1)
      @response2 = setup_rack.call(env2)
      @response2.first.should == 401
    end

    it "should not allow to access very secret resources with invalid consumer key" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key + "invalid",
        :oauth_token => @access_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should not allow to access very secret resources with invalid token" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @access_token.token + "invalid",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should not allow to access very secret resources with invalid signature" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key,
        :oauth_token => @access_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret + "invalid"
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end

    it "should not allow to access very secret resources with invalid keys" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @client_application.key + "invalid",
        :oauth_token => @access_token.token + "invalid",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @client_application.secret + "%26" + @access_token.secret + "invalid"
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end    
  end  
end

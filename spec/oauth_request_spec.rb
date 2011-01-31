require 'spec_helper'

describe "OAuth request" do

  context "Success" do

    it "should allow to access very secret resources" do
      @user = Factory(:user)
      @access_token = Factory.create(:access_token, :user => @user, :client_application => Factory.create(:client_application))
      
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => @access_token.client_application.key,
        :oauth_token => @access_token.token,
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => @access_token.client_application.secret + "%26" + @access_token.secret
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 200
    end
    
  end
  
  context "Failure" do
    
    it "should allow to access very secret resources" do
      auth_str = oauth_header({
        :realm => "MoneyBird",
        :oauth_consumer_key => "2134",
        :oauth_token => "abcd",
        :oauth_signature_method => "PLAINTEXT",
        :oauth_timestamp => Time.now.to_i,
        :oauth_nonce => Time.now.to_f,
        :oauth_signature => "12345"
      })
      
      env = env_with_params("/invoices", {}, {
        "HTTP_AUTHORIZATION" => auth_str
      })
      @response = setup_rack.call(env)
      @response.first.should == 401
    end
    
  end
  
end

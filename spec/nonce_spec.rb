require 'spec_helper'

describe WardenOauthProvider::Nonce do
  before(:each) do
    @oauth_nonce = WardenOauthProvider::Nonce.remember(Time.now.to_f, Time.now.to_i)
  end

  it "should be valid" do
    @oauth_nonce.should be_valid
  end
  
  it "should not have errors" do
    @oauth_nonce.errors.full_messages.should == []
  end
  
  it "should not be a new record" do
    @oauth_nonce.should_not be_new_record
  end
  
  it "should not allow a second one with the same values" do
    WardenOauthProvider::Nonce.remember(@oauth_nonce.nonce, @oauth_nonce.timestamp).should == false
  end
end
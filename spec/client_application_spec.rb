require 'spec_helper'

describe WardenOauthProvider::ClientApplication do 

  it "should be valid with valid attributes" do
    @application = WardenOauthProvider::ClientApplication.create(:name => "Test application", :url => "http://testapp.com")
    @application.should be_valid
  end

  it "should be invalid with invalid attributes" do
    @application = WardenOauthProvider::ClientApplication.new
    @application.valid?
    @application.errors[:name].should_not be_empty
    @application.errors[:url].should_not be_empty
  end
  
  it "should have key and secret" do
    @application = WardenOauthProvider::ClientApplication.create(:name => "Test application", :url => "http://testapp.com")
    @application.key.should_not be_nil
    @application.secret.should_not be_nil
  end
  
  ["http://valid.com",
   "http://valid.com/path"].each do |url|
     it "should allow #{url} as a valid url" do
       @application = WardenOauthProvider::ClientApplication.new(:url => url)
       @application.valid?
       @application.errors[:url].should be_empty
     end
   end
  
  ["ftp://invalid.com",
  "http:://invalid.com"].each do |url|
    it "should not allow #{url} as a valid url" do
      @application = WardenOauthProvider::ClientApplication.new(:url => url)
      @application.valid?
      @application.errors[:url].should_not be_empty
    end
  end
  
end
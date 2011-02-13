require 'spec_helper'

describe WardenOauthProvider::Token::Request do

  before(:all) do
    @client_application = Factory(:client_application)
  end

  before(:each) do
    @token = WardenOauthProvider::Token::Request.create :client_application_id => @client_application.id
  end

  it "should be valid" do
    @token.should be_valid
  end

  it "should not have errors" do
    @token.errors.should_not == []
  end

  it "should have a token" do
    @token.token.should_not be_nil
  end

  it "should have a secret" do
    @token.secret.should_not be_nil
  end

  it "should not be authorized" do
    @token.should_not be_authorized
  end

  it "should not be invalidated" do
    @token.should_not be_invalidated
  end

  it "should not have a verifier" do
    @token.verifier.should be_nil
  end

  it "should be oob" do
    @token.should be_oob
  end

  describe "OAuth 1.0a" do

    describe "with provided callback" do
      before(:each) do
        @token.callback_url="http://test.com/callback"
      end

      it "should not be oob" do
        @token.should_not be_oob
      end

      describe "authorize request" do
        before(:each) do
          @user = Factory(:user)
          @token.authorize!(@user)
        end

        it "should be authorized" do
          @token.should be_authorized
        end

        it "should have authorized at" do
          @token.authorized_at.should_not be_nil
        end

        it "should have user set" do
          @token.user.should == @user
        end

        it "should have verifier" do
          @token.verifier.should_not be_nil
        end

        describe "exchange for access token" do

          before(:each) do
            @access = @token.exchange!(@token.verifier)
          end

          it "should be valid" do
            @access.should be_valid
          end

          it "should have no error messages" do
            @access.errors.full_messages.should==[]
          end

          it "should invalidate request token" do
            @token.should be_invalidated
          end

          it "should set user on access token" do
            @access.user.should == @user
          end

          it "should authorize accesstoken" do
            @access.should be_authorized
          end
        end

        describe "attempt exchange with invalid verifier (OAuth 1.0a)" do

          before(:each) do
            @value = @token.exchange!("invalidverifier")
          end

          it "should return false" do
            @value.should==false
          end

          it "should not invalidate request token" do
            @token.should_not be_invalidated
          end
        end

      end

      describe "attempt exchange with out authorization" do

        before(:each) do
          @value = @token.exchange!("invalidverifier")
        end

        it "should return false" do
          @value.should==false
        end

        it "should not invalidate request token" do
          @token.should_not be_invalidated
        end
      end

    end

    describe "with oob callback" do
      before(:each) do
        @token.callback_url='oob'
      end

      it "should be oob" do
        @token.should be_oob
      end

      describe "authorize request" do
        before(:each) do
          @user = Factory(:user)
          @token.authorize!(@user)
        end

        it "should be authorized" do
          @token.should be_authorized
        end

        it "should have authorized at" do
          @token.authorized_at.should_not be_nil
        end

        it "should have user set" do
          @token.user.should == @user
        end

        it "should have verifier" do
          @token.verifier.should_not be_nil
        end

        describe "exchange for access token" do

          before(:each) do
            @access = @token.exchange!(@token.verifier)
          end

          it "should invalidate request token" do
            @token.should be_invalidated
          end

          it "should set user on access token" do
            @access.user.should == @user
          end

          it "should authorize accesstoken" do
            @access.should be_authorized
          end
        end

        describe "attempt exchange with invalid verifier (OAuth 1.0a)" do

          before(:each) do
            @value = @token.exchange!("foobar")
          end

          it "should return false" do
            @value.should==false
          end

          it "should not invalidate request token" do
            @token.should_not be_invalidated
          end
        end

      end

      describe "attempt exchange with out authorization invalid verifier" do

        before(:each) do
          @value = @token.exchange!("foobar")
        end

        it "should return false" do
          @value.should==false
        end

        it "should not invalidate request token" do
          @token.should_not be_invalidated
        end
      end
    end
  end
end
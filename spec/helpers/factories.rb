Factory.define(:client_application, :class => WardenOauthProvider::ClientApplication) do |f|
  f.name            "Example client application"
  f.url             "http://www.example.com"
  f.support_url     "http://www.example.com/support"
  f.callback_url    "http://www.example.com/callback"
end

Factory.define(:request_token, :class => WardenOauthProvider::Token::Request) do |f|
end

Factory.define(:access_token, :class => WardenOauthProvider::Token::Access) do |f|
end

Factory.define(:user) do |f|
  f.name "John"
end
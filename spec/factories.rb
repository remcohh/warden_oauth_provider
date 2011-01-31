Factory.define(:client_application, :class => WardenOauthProvider::ClientApplication) do |f|
  f.name            "Example client application"
  f.url             "http://www.example.com"
  f.support_url     "http://www.example.com/support"
  f.callback_url    "http://www.example.com/callback"
end
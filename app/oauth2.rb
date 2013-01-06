require 'faraday'
require 'faraday_middleware'

class OAuth2Bearer < Faraday::Middleware
  def call(env)
    env[:request_headers]['Authorization'] = "Bearer #{@token}"
    @app.call env
  end
  def initialize(app, token = nil)
    super app
    @token = token
  end
end

Faraday.register_middleware :request, :oauth2bearer => lambda { OAuth2Bearer }

$the_app_token = nil
def app_token
  if $the_app_token.nil?
    $the_app_token = Faraday.new(:url => 'https://account.app.net/') do |a|
      a.request  :url_encoded 
      a.response :json, :content_type => /\bjson$/
      a.adapter  Faraday.default_adapter
    end.post('oauth/access_token', :client_id => ENV['ADN_ID'], :client_secret => ENV['ADN_SECRET'], :grant_type => 'client_credentials').body['access_token']
  end
  $the_app_token
end

def adn(token)
  Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
    adn.request  :oauth2bearer, token || app_token
    adn.request  :json
    adn.response :json, :content_type => /\bjson$/
    adn.adapter  Faraday.default_adapter
  end
end

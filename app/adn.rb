require 'faraday'
require 'faraday_middleware'

class ADN
  def initialize(token)
    @api = Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
      adn.request  :authorization, 'Bearer', token
      adn.request  :json
      adn.response :json, :content_type => /\bjson$/
      adn.adapter  Faraday.default_adapter
    end
  end

  def method_missing(meth, *args)
    @api.send meth, *args
  end

  def me
    @api.get('users/me').body['data']
  end

  def new_post(params)
    post 'posts', params
  end
end

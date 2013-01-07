require 'faraday'
require 'faraday_middleware'

class ADN
  def initialize(token)
    @api = Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
      adn.request  :authorization, 'Bearer', token || app_token
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

  def get_replies(post_id, before_id)
    rsp = @api.get("posts/#{post_id}/replies",
                   :count => 200,
                   :include_machine => 1, :include_post_annotations => 1,
                   :before_id => before_id).body
    replies = rsp['data']
    if rsp['meta']['more']
      get_replies(post_id, rsp['meta']['min_id']) + replies
    else
      replies
    end
  end

  def new_post(params)
    post 'posts', params
  end
end

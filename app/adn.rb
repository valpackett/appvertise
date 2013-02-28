require 'sinatra/base'
require 'patron'
require 'faraday'
require 'faraday_middleware'
require_relative 'const'

class ADN
  class << self
    attr_accessor :global
  end

  def initialize(token)
    @api = Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
      adn.request  :authorization, 'Bearer', token
      adn.request  :multipart
      adn.request  :json
      adn.response :json, :content_type => /\bjson$/
      adn.adapter  :patron
    end
  end

  def method_missing(*args)
    @api.send *args
  end

  def me
    @api.get('users/me').body['data']
  end

  def new_post(params)
    @api.post 'posts', params
  end

  def new_file(file, params)
    payload = params.dup
    payload[:content] = Faraday::UploadIO.new file[:tempfile].path, file[:type]
    @api.post 'files', payload
  end

  def get_file(id)
    @api.get "files/#{id}"
  end

  def delete_file(id)
    @api.delete "files/#{id}"
  end
end

ADN.global = ADN.new ADN_TOKEN

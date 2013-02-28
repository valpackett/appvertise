require_relative 'const.rb'
require 'patron'
require 'faraday'
require 'faraday_middleware'

class Blockchain
  class << self
    attr_accessor :host, :api

    def new_receive_address(id)
      @api.get('api/receive',
              :method => 'create',
              :address => BTC_ADR,
              :callback => "http://#{@host}/btc/callback?id=#{id}").body['input_address']
    end

    def pay(amount, adr)
      @api.get("merchant/#{BTC_GUID}/payment",
              :password => BTC_PASSWORD,
              :second_password => BTC_PASSWORD2,
              :to => adr,
              :amount => (amount * 100000000).round).body
    end
  end
end

Blockchain.api = Faraday.new(:url => 'https://blockchain.info/') do |b|
  b.request  :url_encoded
  b.response :json, :content_type => /\bjson$/
  b.adapter  :patron
end

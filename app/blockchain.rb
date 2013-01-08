require 'faraday'

class Blockchain
  class << self
    attr_accessor :host
    def initialize
      @api = Faraday.new(:url => 'https://blockchain.info/') do |b|
        b.request  :url_encoded
        b.response :json, :content_type => /\bjson$/
        b.adapter  Faraday.default_adapter
      end
    end
  end

  def self.new_receive_address(id)
    api.get('api/receive',
            :method => 'create',
            :address => ENV['BTC_ADR'],
            :callback => "http://#{@host}/btc/callback?id=#{id}").body['input_address']
  end

  def self.pay(amount, adr)
    api.get("merchant/#{ENV['BTC_GUID']}/payment",
            :password => ENV['BTC_PASSWORD'],
            :second_password => ENV['BTC_PASSWORD2'],
            :to => adr,
            :amount => (amount * 100000000).round).body
  end
end

require 'coinbase'
require_relative 'const'

class Bitcoin
  class << self
    attr_accessor :api

    def generate_receive_address(callback_url)
      @api.generate_receive_address(:address => {
        :callback_url => callback_url
      })[:address]
    end

    def send_money(adr, amount)
      @api.send_money adr, amount
    end
  end
end

Bitcoin.api = Coinbase::Client.new BTC_KEY

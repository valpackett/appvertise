require 'aws-sdk'
require 'faraday'
require 'securerandom'

AWS.config(:access_key_id => ENV['AWS_KEY'], :secret_access_key => ENV['AWS_SECRET'])

$blockchain = Faraday.new(:url => 'https://blockchain.info/') do |b|
  b.request  :url_encoded
  b.response :json, :content_type => /\bjson$/
  b.adapter  Faraday.default_adapter
end

helpers do
  def upload(file)
    o = AWS::S3.new.buckets.create(ENV['AWS_BUCKET']).objects[SecureRandom.hex + file[:filename]]
    o.write :file => file[:tempfile].path
    o.public_url.to_s
  end

  def bitcoin_recv_adr(id)
    $blockchain.get('api/receive', :method => 'create', :address => ENV['BTC_ADR'],
                    :callback => "http://#{request.host}/btc/callback?id=#{id}").body['input_address']
  end

  def pay_bitcoins(amount, adr)
    $blockchain.get("merchant/#{ENV['BTC_GUID']}/payment",
                    :password   => ENV['BTC_PASSWORD'],
                    :second_password => ENV['BTC_PASSWORD2'],
                    :to => adr,
                    :amount => (amount * 100000000).round).body
  end

  def total(keys)
    keys.map { |k| k.balance }.reduce { |a, b| a + b }
  end
end

require_relative 'adn.rb'
require_relative 'models.rb'
require_relative 'const.rb'

class Numeric
  def cut_percents(p)
    self - (self / 100 * p)
  end
end

class Worker
  class << self
    attr_accessor :host
  end

  def self.ann(post)
    p = post['annotations'].select { |a| a['type'] == ANN_TYPE }.first
    p['value'] unless p.nil?
  end

  def self.calculate_paid_through(balance)
    # Time + Numeric adds seconds
    Time.now + (balance / BTC_PER_HOUR * 60 * 60)
  end

  def self.count_clicks(ad)
    clicks = {}
    ad.clicks.each do |k, v|
      clicks[k] = v.values.length
    end
    clicks
  end

  def self.pay_rewards(ad)
    to_pay = ad.balance.cut_percents PERCENT_CUT
    clicks = count_clicks ad
    unless clicks.empty?
      puts "Paying #{to_pay} of #{ad.balance} BTC for ad #{ad.id}"
      total_clicks = clicks.values.reduce { |a, b| a + b }
      click_cost = to_pay / total_clicks
      clicks.each do |id, clicks|
        key = KeyRepository.find_by_id id
        key.balance += click_cost * clicks
        KeyRepository.save key
      end
    end
  end

  def self.post_new_ad
    ad = AdRepository.earliest_unposted_paid_ad
    unless ad.nil?
      puts "Posting ad #{ad.id}"
      paid_through = calculate_paid_through ad.balance
      url = "http://#{@host || HOST}/ads/#{ad.id.to_s}/click"
      p url
      post = ADN.global.new_post :text => ad.txt, :entities => {
        :links => [ { :pos => 0, :len => ad.txt.length, :url => url } ]
      }, :annotations => [
        { :type => ANN_TYPE,
          :value => { :paid_through => paid_through.to_s } },
        { :type => 'net.app.core.oembed',
          :value => { '+net.app.core.file' => { :file_id => ad.img_id, :file_token => ad.img_token, :format => :oembed } } }
      ]
      ad.paid_through = paid_through
      p post.body
      ad.adn_id = post.body['data']['id']
      ad.is_posted = true
      AdRepository.save ad
      puts "Posted ad #{ad.id} as adn_id #{ad.adn_id}"
    end
  end

  def self.work
    last_ad = AdRepository.last_posted_ad
    if last_ad
      if last_ad.paid_through < Time.now
        pay_rewards last_ad
        AdRepository.delete last_ad
        post_new_ad
      end
    else
      post_new_ad
    end
  end
end


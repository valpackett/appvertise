require 'rufus/scheduler'
require_relative 'oauth2.rb'
require_relative 'models.rb'
require_relative 'const.rb'

$ads_adn = adn ENV['ADN_TOKEN']

class Numeric
  def cut_percents(p)
    self - (self / 100 * p)
  end
end

class Worker
  def self.ann(post)
    p = post['annotations'].select { |a| a['type'] == ANN_TYPE }.first
    p['value'] unless p.nil?
  end

  def self.click_ann(post)
    p = post['annotations'].select { |a| a['type'] == CLICK_ANN_TYPE }.first
    p['value'] unless p.nil?
  end

  def self.valid_replies(post)
    # TODO: support more than 200
    $ads_adn.get("posts/#{post['id']}/replies?count=200&include_machine=1&include_post_annotations=1").body['data'].select { |p|
      p['machine_only'] == true and !p['annotations'].nil?
    }
  end

  def self.paid_through(post)
    DateTime.parse(ann(post)['paid_through']).to_time
  end

  def self.calculate_paid_through(balance)
    # Time + Numeric adds seconds
    Time.now + (balance / ENV['BTC_PER_HOUR'].to_f * 60 * 60)
  end

  def self.valid_click?(new_time, times)
    # Time - Time returns seconds
    # using .abs means we don't have to care about order
    times.map { |t| (t - new_time).abs >= 30 * 60 }.all?
  end

  def self.count_clicks(replies)
    clicks = {}
    # To validate clicks, clicks is key => sender_id => click times
    replies.each do |p|
      a = click_ann p
      unless a.nil?
        key = a['key']
        sender_id = p['user']['id']
        time = DateTime.parse(p['created_at']).to_time
        clicks[key] ||= {}
        clicks[key][sender_id] ||= []
        clicks[key][sender_id] << time if valid_click? time, clicks[key][sender_id]
      end
    end
    # Don't need to store times anymore, make clicks just key => click count
    clicks.each do |k, v|
      clicks[k] = v.values.flatten.length
    end
    clicks
  end

  def self.pay_rewards(ad, post)
    to_pay = ad.balance.cut_percents PERCENT_CUT
    puts "Paying #{to_pay} of #{ad.balance} BTC for ad #{ad.id}"
    replies = valid_replies post
    clicks = count_clicks replies
    total_clicks = clicks.values.reduce { |a, b| a + b }
    click_cost = to_pay / total_clicks
    clicks.each do |id, clicks|
      key = KeyRepository.find_by_id id
      key.balance += click_cost * clicks
      KeyRepository.save key
    end
  end

  def self.delete_ad(ad)
    AdRepository.delete ad
  end

  def self.post_new_ad
    ad = AdRepository.all.select { |a|
      !a.balance.nil? and a.balance > 0.0 and !a.is_posted
    }.sort_by { |a| a.updated_at }.first
    unless ad.nil?
      puts "Posting ad #{ad.id}"
      post = $ads_adn.post 'posts', :text => "#{ad.txt.slice 0, (255-ad.url.length)} #{ad.url}", :annotations => [{
        :type => ANN_TYPE,
        :value => {
          :text => ad.txt, :url => ad.url, :img => ad.img,
          :paid_through => calculate_paid_through(ad.balance).to_s
        }
      }]
      ad.adn_id = post.body['data']['id']
      ad.is_posted = true
      AdRepository.save ad
      puts "Posted ad #{ad.id} as adn_id #{ad.adn_id}"
    end
  end

  def self.work
    last_post = $ads_adn.get('users/me/posts?include_post_annotations=1&count=1').body['data'][0]
    last_ad = AdRepository.find_first_by_adn_id last_post['id']
    if last_ad
      if paid_through(last_post) < Time.now
        pay_rewards(last_ad, last_post)
        delete_ad(last_ad)
        post_new_ad
      end
    else # First ad of the account
      post_new_ad
    end
  end

  def self.start
    scheduler = Rufus::Scheduler.start_new
    scheduler.every '1m' do
      work
    end
    puts '>> Worker started'
  end
end

require 'curator'
require 'uri'
require 'mongo'

mongolab_uri = ENV['MONGOLAB_URI']
unless mongolab_uri.nil?
  uri  = URI.parse mongolab_uri
  conn = Mongo::Connection.from_uri mongolab_uri
  db   = uri.path.gsub /^\//, ''
else
  conn = Mongo::Connection.new
  db   = "appvertise"
end

Curator.configure(:mongo) do |config|
  config.environment = "development"
  config.client      = conn
  config.database    = db
  config.migrations_path = File.expand_path(File.dirname(__FILE__) + "../migrations")
end


class Ad
  include Curator::Model
  attr_accessor :id, :adn_id, :owner_adn_id, :btc_adr, :txt, :url, :img, :is_posted, :balance, :transactions, :paid_through

  def live_time
    l = AdRepository.last_posted_ad
    unless l.nil?
      base = l.paid_through
    else
      base = Time.now
    end
    times = AdRepository.all.select { |a|
      !a.is_posted and a.balance > 0.0 and a != self and a.updated_at < self.updated_at
    }.map { |a|
      a.balance / ENV['BTC_PER_HOUR'].to_f * 60 * 60
    }
    unless times.empty?
      base + times.reduce { |a, b| a + b }
    else
      base
    end
  end
end

class AdRepository
  include Curator::Repository
  indexed_fields :owner_adn_id, :adn_id

  def self.earliest_unposted_paid_ad
    all.select { |a|
      a.balance > 0.0 and !a.is_posted
    }.sort_by { |a| a.updated_at }.first
  end

  def self.last_posted_ad
    all.select { |a| a.is_posted }.sort_by { |a| a.updated_at }.last
  end
end


class Key
  include Curator::Model
  attr_accessor :id, :owner_adn_id, :name, :balance
end

class KeyRepository
  include Curator::Repository
  indexed_fields :owner_adn_id
end

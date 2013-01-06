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
end

class AdRepository
  include Curator::Repository
  indexed_fields :owner_adn_id, :adn_id
end


class Key
  include Curator::Model
  attr_accessor :id, :owner_adn_id, :name, :balance
end

class KeyRepository
  include Curator::Repository
  indexed_fields :owner_adn_id
end

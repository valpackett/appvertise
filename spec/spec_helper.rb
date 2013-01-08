require 'rack/test'
require_relative '../app/app.rb'

class Appvertise
  set :environment, :test
  set :raise_errors, true
  set :logging, false
end

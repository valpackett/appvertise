require 'rack/test'
require_relative '../app/app.rb'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

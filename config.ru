require 'rubygems'
require 'sinatra'
require './app/app.rb'

Worker.start
Thread.new do
  Worker.work
end

run Sinatra::Application

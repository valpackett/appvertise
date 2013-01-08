require 'rubygems'
require './app/app.rb'
require './app/worker.rb'

Worker.start
Thread.new do
  Worker.work
end

run Appvertise

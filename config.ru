require 'rubygems'
require 'rufus/scheduler'
require './app/app.rb'
require './app/worker.rb'

Thread.new { Worker.work }
Rufus::Scheduler.start_new.every('1m') { Worker.work }
puts '>> Worker started'

run Appvertise

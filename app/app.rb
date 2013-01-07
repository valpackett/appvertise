require 'sinatra'
require 'sinatra/flash'
require 'rack/csrf'
require 'omniauth'
require 'omniauth-appdotnet'
require 'slim'
require_relative 'oauth2.rb'
require_relative 'models.rb'
require_relative 'helpers.rb'
require_relative 'validator.rb'
require_relative 'worker.rb'

Worker.start
Thread.new do
  Worker.work
end

enable :sessions
set :session_secret, ENV['SECRET_KEY'] || 'aaaaa'
set :server, :thin
set :port, 8080
set :markdown, :layout_engine => :slim
use Rack::Session::Cookie
#use Rack::Csrf
use OmniAuth::Builder do
  provider :appdotnet, ENV['ADN_ID'], ENV['ADN_SECRET'], :scope => 'write_post'
end

before do
  @adn = ADN.new session[:token]
  unless session[:token].nil?
    @me = @adn.get('users/me').body['data']
  end
end

not_found do
  slim :not_found
end

get '/auth/appdotnet/callback' do
  session[:token] = request.env['omniauth.auth']['credentials']['token']
  redirect request.env['omniauth.origin'] || '/'
end

get '/auth/logout' do
  session[:token] = nil
  redirect '/'
end

get '/' do
  unless @me.nil?
    @keys = KeyRepository.find_by_owner_adn_id @me['id']
    @ads  =  AdRepository.find_by_owner_adn_id @me['id']
    @balance = total @keys
    slim :index
  else
    slim :landing
  end
end

get '/docs' do
  markdown :docs
end

post '/fuck_you_pay_me' do
  keys = KeyRepository.find_by_owner_adn_id @me['id']
  result = pay_bitcoins total(keys), params[:adr]
  if result['error'].nil?
    keys.each do |k|
      k.balance = 0.0
      KeyRepository.save k
    end
    flash[:message] = result['message'] + "\n" + result['notice']
  else
    puts result
    flash[:error] = result['error']
  end
  redirect '/'
end

get '/btc/callback' do
  puts "Blockchain callback: #{params}"
  if params[:address] == ENV['BTC_ADR']
    ad = AdRepository.find_by_id params[:id]
    ad.balance += params[:value].to_f / 100000000
    ad.transactions ||= []
    ad.transactions << params[:transaction_hash]
    AdRepository.save ad
  end
end

# /keys {{{
post '/keys' do
  begin
    Validator.valid_key? params
    key = Key.new :name => params[:name], :owner_adn_id => @me['id'], :balance => 0.0
    KeyRepository.save key
  rescue ValidationException => e
    flash[:error] = e.message
  end
  redirect '/'
end

get '/keys/:id/delete' do
  KeyRepository.delete(KeyRepository.find_by_id params[:id])
  flash[:message] = 'Successfully deleted your key.'
  redirect '/'
end
# }}}

# /ads {{{
post '/ads' do
  begin
    Validator.valid_ad? params
    ad = Ad.new :owner_adn_id => @me['id'], :txt => params[:txt], :url => params[:url],
                :img => upload(params[:img]), :is_posted => false, :balance => 0.0
    AdRepository.save ad
    ad.btc_adr = bitcoin_recv_adr(ad.id.to_s)
    AdRepository.save ad
  rescue ValidationException => e
    flash[:error] = e.message
  end
  redirect '/'
end

get '/ads/:id/delete' do
  AdRepository.delete(AdRepository.find_by_id params[:id])
  flash[:message] = 'Successfully deleted your ad.'
  redirect '/'
end
# }}}

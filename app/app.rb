require 'sinatra/base'
require 'sinatra/flash'
require 'rack/csrf'
require 'rack/ssl-enforcer'
require 'omniauth'
require 'omniauth-appdotnet'
require 'slim'
require 'digest/md5'
require_relative 's3.rb'
require_relative 'adn.rb'
require_relative 'blockchain.rb'
require_relative 'models.rb'
require_relative 'validator.rb'
require_relative 'worker.rb'

class Appvertise < Sinatra::Base
  set :session_secret, SESSION_SECRET
  set :server, :thin
  set :port, 8080
  set :markdown, :layout_engine => :slim
  set :views, File.join(File.dirname(__FILE__), '..', 'views')
  set :public_folder, File.join(File.dirname(__FILE__), '..', 'public')

  register Sinatra::Flash

  configure :production do
    use Rack::SslEnforcer
  end
  use Rack::Session::Cookie, :secret => settings.session_secret
  use Rack::Csrf
  use OmniAuth::Builder do
    provider :appdotnet, ADN_ID, ADN_SECRET, :scope => 'write_post'
  end

  helpers do
    def total(keys)
      keys.map { |k| k.balance }.reduce { |a, b| a + b }
    end
  end

  before do
    Worker.host = request.host
    Blockchain.host = request.host
    @adn = ADN.new session[:token]
    @me = @adn.me unless session[:token].nil?
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
    result = Blockchain.pay total(keys), params[:adr]
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
    if params[:address] == BTC_ADR
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
                  :img => S3.upload(params[:img]), :is_posted => false, :balance => 0.0
      AdRepository.save ad
      ad.btc_adr = Blockchain.new_receive_address ad.id.to_s
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

  get '/ads/:id/click' do
    ad = AdRepository.find_by_id params[:id]
    # Only count clicks from the same IP
    iphash = Digest::MD5.hexdigest request.ip
    ad.clicks ||= {}
    ad.clicks[params[:key]] ||= []
    clicks = ad.clicks[params[:key]] # [['iphash', Time], ...]
    if clicks.empty? or clicks.map { |c| c.first != iphash or c.last + 30*60 < Time.now }.all?
      clicks << [iphash, Time.now]
      AdRepository.save ad
    end
    redirect ad.url
  end
  # }}}
end

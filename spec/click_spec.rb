require_relative 'spec_helper'
require 'timecop'
require 'digest/md5'

describe '/ad/:id/click' do
  include Rack::Test::Methods
  IP_HASH = Digest::MD5.hexdigest '127.0.0.1'

  def app; Appvertise; end

  before do
    AdRepository.stub :save => nil, :find_by_id => Ad.new()
  end

  after do
    Timecop.return
  end

  it 'redirects to the url' do
    AdRepository.stub :find_by_id => Ad.new(:url => 'http://example.com')
    get '/ads/1/click'
    last_response.headers['Location'].should == 'http://example.com'
  end

  it 'saves clicks when there are no clicks' do
    Timecop.freeze Time.now
    AdRepository.should_receive(:save) { |ad|
      ad.clicks.should == {'abc' => [[IP_HASH, Time.now]]}
    }
    get '/ads/1/click?key=abc'
  end

  context 'with same ip and different key' do
    it 'saves clicks' do
      AdRepository.stub :find_by_id => Ad.new(
        :clicks => {'different' => [[IP_HASH, Time.now]]}
      )
      AdRepository.should_receive(:save) { |ad|
        ad.clicks.length.should == 2
      }
      get '/ads/1/click?key=abc'
    end
  end

  context 'with different ip and same key' do
    it 'saves clicks' do
      AdRepository.stub :find_by_id => Ad.new(
        :clicks => {'abc' => [['rsaohvan34tq34hq3ldhv3', Time.now]]}
      )
      AdRepository.should_receive(:save) { |ad|
        ad.clicks['abc'].length.should == 2
      }
      get '/ads/1/click?key=abc'
    end
  end

  context 'with same ip and key' do
    before do
      AdRepository.stub :find_by_id => Ad.new(
        :clicks => {'abc' => [[IP_HASH, Time.now], ['ohwsvoswvnh234t', Time.now + 60]]}
      )
    end

    it 'does not save clicks within 30 minutes' do
      AdRepository.should_not_receive(:save)
      Timecop.travel Time.now + 29 * 60
      get '/ads/1/click?key=abc'
    end

    it 'saves clicks after 30 minutes' do
      AdRepository.should_receive(:save) { |ad|
        ad.clicks.first.last.length.should == 3
      }
      Timecop.travel Time.now + 31 * 60
      get '/ads/1/click?key=abc'
    end
  end
end

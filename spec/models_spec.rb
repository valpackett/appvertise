require_relative '../app/models.rb'
require 'timecop'

describe Ad do
  before do
    Timecop.freeze Time.now
    AdRepository.stub :last_posted_ad => nil, :all => []
  end

  it 'calculates live time when it is the only ad' do
    subject.live_time.should == Time.now
  end

  it 'calculates live time when there is a posted ad and no more ads' do
    AdRepository.stub :last_posted_ad => stub(:paid_through => Time.now + 60)
    subject.live_time.should == Time.now + 60
  end

  it 'calculates live time when there is a paid unposted ad' do
    AdRepository.stub :all => [Ad.new(:balance => 1.0, :is_posted => false, :updated_at => Time.now - 60, :id => 0)]
    subject.instance_variable_set '@updated_at', Time.now
    subject.live_time.should == Time.now + 1.0 / BTC_PER_HOUR * 60 * 60
  end

  it 'calculates live time when there are paid unposted ads and a posted ad' do
    AdRepository.stub :all => [
        Ad.new(:balance => 1.0, :is_posted => false, :updated_at => Time.now - 60,  :id => 0),
        Ad.new(:balance => 2.0, :is_posted => false, :updated_at => Time.now - 120, :id => 9),
      ],
      :last_posted_ad => stub(:paid_through => Time.now + 60)
    subject.instance_variable_set '@updated_at', Time.now
    subject.live_time.should == Time.now + 60 + (1.0 / BTC_PER_HOUR * 60 * 60) + (2.0 / BTC_PER_HOUR * 60 * 60)
  end
end

describe AdRepository do
  before do
    Timecop.freeze Time.now
  end

  it 'finds the last posted ad' do
    AdRepository.stub :all => [
      Ad.new(:id => 1, :is_posted => false, :updated_at => Time.now + 240),
      Ad.new(:id => 2, :is_posted => true,  :updated_at => Time.now - 120),
      Ad.new(:id => 3, :is_posted => true,  :updated_at => Time.now - 240)
    ]
    AdRepository.last_posted_ad.id.should == 2
  end

  it 'finds the earliest unposted paid ad' do
    AdRepository.stub :all => [
      Ad.new(:id => 1, :balance => 0.0, :is_posted => false, :updated_at => Time.now),
      Ad.new(:id => 2, :balance => 0.0, :is_posted => true,  :updated_at => Time.now),
      Ad.new(:id => 3, :balance => 1.0, :is_posted => false, :updated_at => Time.now),
      Ad.new(:id => 4, :balance => 1.0, :is_posted => false, :updated_at => Time.now - 60),
      Ad.new(:id => 5, :balance => 1.0, :is_posted => true,  :updated_at => Time.now),
    ]
    AdRepository.earliest_unposted_paid_ad.id.should == 4
  end
end

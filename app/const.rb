SESSION_SECRET = ENV['SECRET_KEY'] || 'aaaaa'
HOST = ENV['HOST'] || 'appvertise-it.herokuapp.com'

MONGOLAB_URI = ENV['MONGOLAB_URI']

IMG_TYPE = 'com.floatboth.appvertise.adimage'
ANN_TYPE = 'com.floatboth.appvertise.ad'
ADN_ID = ENV['ADN_ID']
ADN_SECRET = ENV['ADN_SECRET']
ADN_TOKEN = ENV['ADN_TOKEN']

PERCENT_CUT = 30
BTC_PER_HOUR = ENV['BTC_PER_HOUR'].to_f
BTC_KEY = ENV['BTC_KEY']

require 'aws-sdk'
require 'securerandom'

AWS.config(:access_key_id => ENV['AWS_KEY'], :secret_access_key => ENV['AWS_SECRET'])

class S3
  def self.upload(file)
    o = AWS::S3.new.buckets.create(ENV['AWS_BUCKET']).objects[SecureRandom.hex + file[:filename]]
    o.write :file => file[:tempfile].path
    o.public_url.to_s
  end
end

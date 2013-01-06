require 'fastimage'
require_relative 'models.rb'

class ValidationException < Exception
end

class Validator
  def self.valid_key?(params)
    raise ValidationException, "Key name can't be longer than 128 characters" if params[:name].length > 128
    true
  end

  def self.valid_ad?(params)
    raise ValidationException, "Text can't be longer than 255 characters" if params[:txt].length > 255
    raise ValidationException,  "URL can't be longer than 128 characters" if params[:url].length > 128
    img = FastImage.new params[:img][:tempfile]
    raise ValidationException, "Image should be valid" if img.type.nil?
    raise ValidationException, "Image size should be 130 by 100 pixels" unless img.size == [130, 100]
    true
  end
end

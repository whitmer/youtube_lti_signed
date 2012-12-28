require './youtube_lti.rb'

config = AppConfig.generate_new
puts
puts "== New Configuration =="
puts "consumer key:  " + config.consumer_key
puts "shared secret: " + config.shared_secret
puts
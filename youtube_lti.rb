begin
  require 'rubygems'
rescue LoadError
  puts "You must install rubygems to run this example"
  raise
end

begin
  require 'bundler/setup'
rescue LoadError
  puts "to set up this example, run these commands:"
  puts "  gem install bundler"
  puts "  bundle install"
  raise
end

require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'oauth/request_proxy/rack_request'
require 'ims/lti'

# Sinatra wants to set x-frame-options by default, disable it
disable :protection
# Enable sessions so we can remember the launch info between http requests, as
# the user takes the assessment
enable :sessions



# Handle POST requests to the endpoint "/lti_launch"
post "/lti_launch" do
  config = AppConfig.first(:consumer_key => params['oauth_consumer_key'])
  if !config
    return "Invalid launch - no configuration found for that key"
  end
  provider = IMS::LTI::ToolProvider.new(config.consumer_key, config.shared_secret, params)
  if !provider.valid_request?(request)
    return "Invalid launch - signature does not match"
  end
  
  return "missing required values" unless params['resource_link_id'] && params['tool_consumer_instance_guid']
  placement_id = params['resource_link_id'] + 
      params['tool_consumer_instance_guid']
  placement = Placement.first(:placement_id => placement_id)
  if placement
    # Use /embed instead of /v or it won't work in an iframe.
    # It's also a good idea to use https whenever possible, since some
    # platforms (Canvas included) run everything over SSL.
    redirect to "https://youtube.com/embed/"  + placement.video_id
  else
    # use a cookie-based session to remember placement permission
    session["can_set_" + placement_id] = true

    # Let the user pick the video to use for this placement.
    # If you want to make sure students don't pick a video before the teacher
    # can get to this placement, you would check the "roles" parameter.
    redirect to ("/youtube_search.html?placement_id=" + placement_id)
  end
end

# Handle POST requests to the endpoint "/set_video"
post "/set_video" do
  if session["can_set_" + params['placement_id']]
    Placement.create(:placement_id => params['placement_id'], :video_id => params['video_id'])
    return '{"success": true}'
  else
    return '{"success": false}'
  end
end

# Data model to remember placements
class Placement
  include DataMapper::Resource
  property :id, Serial
  property :placement_id, String, :length => 1024
  property :video_id, String
end

class AppConfig
  include DataMapper::Resource
  property :id, Serial
  property :consumer_key, String, :length => 1024
  property :shared_secret, String, :length => 1024
  
  def self.generate_new
    key = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
    secret = Digest::MD5.hexdigest(Time.now.to_i.to_s + rand.to_s)
    create(:consumer_key => key, :shared_secret => secret)
  end
end

env = ENV['RACK_ENV'] || settings.environment
DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/#{env}.sqlite3"))
DataMapper.auto_upgrade!

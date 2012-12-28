YouTube Search LTI App (with signature verification)
---------------------------
This is a really basic app that will let teachers search for
and set links to YouTube videos within their course content.
The app requires the learning platform to have a consumer key
and shared secret (provided by the app) in order to successfully
launch the app.

More information available here:  http://brianwhitmer.blogspot.com/2012/12/lti-authentication.html

### Setting Up

- Make sure ruby is installed
- gem install bundler
- bundle install
- ruby youtube_lti.rb
- The server should now be running at http://localhost:4567
- Set the LTI launch URL to http://loocalhost:4567/lti_launch

### Generating Config
- ruby generate_config.rb
- The key and secret can be shared with a learning platform for launching the app
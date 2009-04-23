# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

URL_FOR_CACHE = "refinr.com/current"

# Gobbler fetch threads
GOBBLER_THREAD_COUNT = 5

# Feed image cache location
FEED_IMAGES_SRC = '/assets/images/feed'
FEED_IMAGES_CACHE_DIR = "/var/www/media.refinr.com/public#{FEED_IMAGES_SRC}"

# Image cache location
ITEM_IMAGES_SRC = "/assets/images/items"
ITEM_IMAGES_CACHE_DIR = "/var/www/media.refinr.com/public#{ITEM_IMAGES_SRC}"

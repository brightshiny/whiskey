# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false
# config.action_controller.perform_caching             = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

# Gobbler fetch threads
GOBBLER_THREAD_COUNT = 2

# Image cache location
ITEM_IMAGES_SRC = "/assets/images/items"
ITEM_IMAGES_CACHE_DIR = File.expand_path("#{RAILS_ROOT}/public/assets/images/items")

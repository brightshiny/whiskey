# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem "ezcrypto", :lit => "ezcrypto"
  config.gem "simple-rss"
  config.gem "authlogic"
  config.gem "htmlentities"
  config.gem "stemmer"
  config.gem "imagesize", :lib => "image_size"
  config.gem "rmagick", :lib => "RMagick"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
  config.time_zone = 'UTC'

  # The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
  # All files from config/locales/*.rb,yml are added automatically.
  # config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_refinr_session',
    :secret      => 'dd3b9e746ce79eca63d34b7e82a3803686ec3db3cd95e80306bdda31783aa123e32d45870a5f6504618d823247db57e82c647a7cd25093ae7c0bb9095848819a'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # Please note that observers generated using script/generate observer need to have an _observer suffix
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  config.cache_store = :file_store, RAILS_ROOT + "/cache"
end

# UserSession.configure do |config|
#   config.remember_me = true
#   config.remember_me_for = 3.months.to_i
# end

require 'ezcrypto_url_safe'
KEY = EzCrypto::Key.with_password "4e3064a5e2e0037812e6b7103fd73091dc29ac7e2cbb3e9a9e3092c4ac48603dd6ff0532bd12bc4ffcf95b36a7f6e7d88633073b28c717ee32c4e59e637dfe1a", "d995ca6318a590fd14df40311ed1b42ef7d96a67548c990e53b77752cd59f4306ee592e0b7010b68229db7fd388250b489111ad90a8e87d14b40576f7625c796", :algorithm=>"aes256"

# The crux of the matter
require 'linalg'

# Should probably find a better place for these...
require 'smtp_tls'
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.default_charset = "utf-8"
ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :domain => "gmail.com",
  :authentication => :login,
  :user_name => "whiskeybrightshinyme@gmail.com",
  :password => "9aHefafaXath&GAz"
}

# From where should images be pulled?
ActionController::Base.asset_host = Proc.new { |source|
  if source.starts_with?('/assets/images')
    "http://media.refinr.com"
  else
    ""
  end
}

require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  has_many :feeds, :through => :feed_users
  has_many :feed_users
  has_many :clicks
  has_many :reads

  validates_length_of :nickname, :within => 3..40
  validates_uniqueness_of :nickname
  validates_format_of :nickname, :with => Authentication.login_regex, :message => Authentication.bad_login_message
  
  validates_presence_of :login, :if => :is_not_open_id?
  validates_length_of :login, :within => 3..40, :if => :is_not_open_id?
  validates_uniqueness_of :login, :if => :is_not_open_id?
  validates_format_of :login, :with => Authentication.login_regex, :message => Authentication.bad_login_message, :if => :is_not_open_id?

  validates_format_of :name, :with => Authentication.name_regex, :message => Authentication.bad_name_message, :allow_nil => true, :if => :is_not_open_id?
  validates_length_of :name, :maximum => 100, :if => :is_not_open_id?

  validates_presence_of :email, :if => :is_not_open_id?
  validates_length_of :email, :within => 6..100, :if => :is_not_open_id? #r@a.wk
  validates_uniqueness_of :email, :if => :is_not_open_id?
  validates_format_of :email, :with => Authentication.email_regex, :message => Authentication.bad_email_message, :if => :is_not_open_id?

  validates_presence_of :password, :if => :password_is_necessary?
  validates_presence_of :password_confirmation, :if => :password_is_necessary?
  validates_confirmation_of :password, :if => :password_is_necessary?
  validates_length_of :password, :within => 6..40, :if => :password_is_necessary?
  
  def password_is_necessary?
    password_is_necessary = false
    if password_required? && is_not_open_id?
      password_is_necessary = true
    end
    return password_is_necessary
  end
  
  def is_not_open_id? # named as to fit the formatting of the validates_as syntax
    (! is_open_id?)
  end
  def is_open_id?
    (! identity_url.nil?)
  end
  
  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :nickname, :password, :password_confirmation, :identity_url

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def token
    KEY.url_safe_encrypt64(self.id.to_s)
  end

  protected
    
end

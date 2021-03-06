require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :feeds, :through => :feed_users
  has_many :feed_users
  has_many :clicks
  has_many :reads
  has_many :runs
  has_many :item_words
  
  attr_accessible :login, :email, :password, :password_confirmation, :openid_identifier
  
  acts_as_authentic :login_field_validation_options => { :if => :openid_identifier_blank? },
                    :password_field_validation_options => { :if => :openid_identifier_blank? },
                    :password_field_validates_length_of_options => { :on => :update, :if => :has_no_credentials? },
                    :cypto_provider => Authlogic::CryptoProviders::BCrypt

  
  def persistence_token
    puts "R RT: #{self.remember_token}"
    self.remember_token
  end
  def persistence_token=(value)
    puts "W RT: #{value}"
    self.remember_token=value
    puts "W RT: #{self.remember_token}"
  end
  
  validate :normalize_openid_identifier
  validates_uniqueness_of :openid_identifier, :allow_blank => true
  
  attr_accessor :foo
  
  # User creation/activation
  def signup!(params)
    self.login = params[:user][:login]
    self.email = params[:user][:email]
    save_without_session_maintenance
  end
  
  def activate!(params)
    self.active = true
    self.password = params[:user][:password]
    self.password_confirmation = params[:user][:password_confirmation]
    save
  end
  
  # For acts_as_authentic configuration
  def openid_identifier_blank?
    openid_identifier.blank?
  end
  
  def has_no_credentials?
    self.crypted_password.blank? && self.openid_identifier.blank?
  end
  
  # Email notifications
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end
  
  def deliver_activation_instructions!
    reset_perishable_token!
    Notifier.deliver_activation_instructions(self)
  end
  
  def deliver_activation_confirmation!
    reset_perishable_token!
    Notifier.deliver_activation_confirmation(self)
  end
  
  # Helper methods
  def active?
    active
  end

  def encrypted_id
    KEY.url_safe_encrypt64(self.id)
  end
  
  def recently_read_items(number_of_items_to_return = 1000)
    Item.find( :all, 
      :conditions => ["`reads`.user_id = ?", self.id], 
      :joins => "join `reads` on `reads`.item_id = items.id",
      :include => [ :words ],
      :order => "`reads`.created_at desc",
      :limit => number_of_items_to_return
    )
  end

  def recently_clicked_items(number_of_items_to_return = 1000)
    Item.find( :all, 
      :conditions => ["`clicks`.user_id = ?", self.id], 
      :joins => "join `clicks` on `clicks`.item_id = items.id",
      :include => [ :words ],
      :order => "`clicks`.created_at desc",
      :limit => number_of_items_to_return
    )
  end
  
  def items_read_on(date, number_of_items_to_return = 1000)
    Item.find(:all, 
      :conditions => ["date(`reads`.created_at) = ?", date],
      :joins => "join `reads` on `reads`.item_id = items.id",
      :include => [ { :item_words, :word } ],
      :order => "`reads`.created_at desc",
      :limit => number_of_items_to_return
    )
  end
  
  def items_clicked_on(date, number_of_items_to_return = 1000)
    Item.find(:all, 
      :conditions => ["date(`clicks`.created_at) = ?", date],
      :joins => "join `clicks` on `clicks`.item_id = items.id",
      :include => [ { :item_words, :word } ],
      :order => "`clicks`.created_at desc",
      :limit => number_of_items_to_return
    )
  end
  
  def document_based_on_recently_clicked_items(number_of_items_to_return = 1000)
    self.recently_clicked_items(number_of_items_to_return).map{ |i| i.words.map{ |w| w.word } }.flatten.join(" ")   
  end
  
  def document_based_on_recently_read_items(number_of_items_to_return = 1000)
    self.recently_read_items(number_of_items_to_return).map{ |i| i.words.map{ |w| w.word } }.flatten.join(" ")    
  end
  
  def recent_documents_from_feeds(number_of_items_to_return = 1000, max_date = nil)
    # Item.find(:all, 
    #   :joins => "join feed_users fu on (fu.feed_id = items.feed_id)",
    #   :conditions => ["fu.user_id = ?", self.id],
    #   :order => "items.published_at desc",
    #   :limit => number_of_items_to_return
    # ) 
    feedusers = FeedUser.find(:all, :conditions => ["user_id = ?", self.id])
    feed_ids = feedusers.map{ |f| f.feed_id }
    items = Item.find(:all, 
      :conditions => ["feed_id in (?) and published_at < ? and parsed_at is not null", feed_ids, Time.now],
      :include => { :item_words => :word },
      :order => "published_at desc", 
      :limit => number_of_items_to_return
    )
    # Item.find_by_sql(["select i.* from items i where i.feed_id in (select feed_id from feed_users fu where fu.user_id = ?) and i.published_at < now() order by i.published_at desc limit ?", self.id, number_of_items_to_return])
  end
  
  def documents_from_feeds_by_date_range(start_date, end_date, number_of_items_to_return = 10000, min_number_of_items_to_return = 500)
    items = Item.find(:all, 
      :joins => "join feed_users fu on (fu.feed_id = items.feed_id)",
      :conditions => ["fu.user_id = ? and items.published_at <= ? and items.published_at >= ?", self.id, end_date, start_date],
      :order => "items.published_at desc",
      :limit => number_of_items_to_return
    ) 
    if items.size < min_number_of_items_to_return 
      items = Item.find(:all,
        :joins => "join feed_users fu on (fu.feed_id = items.feed_id)",
        :conditions => ["fu.user_id = ? and items.published_at <= ? ", self.id, end_date],
        :order => "items.published_at desc",
        :limit => min_number_of_items_to_return
      )
    end
    return items
  end
  
  private
    def normalize_openid_identifier
      begin
        self.openid_identifier = OpenIdAuthentication.normalize_url(openid_identifier) if !openid_identifier.blank?
      rescue OpenIdAuthentication::InvalidOpenId => e
        errors.add(:openid_identifier, e.message)
      end
    end  
end

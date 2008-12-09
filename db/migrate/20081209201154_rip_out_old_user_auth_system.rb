class RipOutOldUserAuthSystem < ActiveRecord::Migration
  def self.up
    
    # Drop old tables
    drop_table :users
    drop_table :open_id_authentication_associations
    drop_table :open_id_authentication_nonces
    
    # Users
    create_table :users do |t|
      t.timestamps
      t.string :login, :null => false
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :remember_token, :null => false
      t.integer :login_count, :default => 0, :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string :last_login_ip
      t.string :current_login_ip
    end
    add_index :users, :login
    add_index :users, :remember_token
    add_index :users, :last_request_at
    
    # Sessions
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    
    # PW reset stuff
    add_column :users, :perishable_token, :string, :default => "", :null => false
    add_column :users, :email, :string, :default => "", :null => false
    add_index :users, :perishable_token
    add_index :users, :email
    
    # OpenID stuff
    add_column :users, :openid_identifier, :string
    add_index :users, :openid_identifier
    change_column :users, :login, :string, :default => nil, :null => true
    change_column :users, :crypted_password, :string, :default => nil, :null => true
    change_column :users, :password_salt, :string, :default => nil, :null => true
    create_table :open_id_authentication_associations, :force => true do |t|
      t.integer :issued, :lifetime
      t.string :handle, :assoc_type
      t.binary :server_url, :secret
    end
    create_table :open_id_authentication_nonces, :force => true do |t|
      t.integer :timestamp, :null => false
      t.string :server_url, :null => true
      t.string :salt, :null => false
    end
    
    # Active users
    add_column :users, :active, :boolean, :default => false

  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
  
  
end

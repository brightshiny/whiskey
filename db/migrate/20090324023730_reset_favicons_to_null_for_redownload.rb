class ResetFaviconsToNullForRedownload < ActiveRecord::Migration
  def self.up
    execute("update feeds set logo = null where id > 0")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end

module EncryptedId
  
  def encrypted_id
    KEY.url_safe_encrypt64(self.id)
  end
  
end
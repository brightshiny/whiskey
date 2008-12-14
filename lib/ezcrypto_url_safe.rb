module EzCrypto
  class Key    
    def url_safe_encrypt64(data)
      Base64.encode64(encrypt(data.to_s)).gsub(/\n/,'').gsub(/\//,'---').gsub(/\+/,'___').gsub(/==/,'').gsub(/=$/i,'')
    end
    def url_safe_decrypt64(data)
      decrypt(Base64.decode64(data.gsub(/___/,'+').gsub(/---/,'/') + "=="))
    end
  end
end

def url_safe_encrypt(key, string)
  KEY.url_safe_encrypt64(string)
end

def url_safe_decrypt(key, string)
  KEY.url_safe_decrypt64(string)
end

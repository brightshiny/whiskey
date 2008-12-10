module Authlogic
  module Session
    # = Cookies
    #
    # Handles all authentication that deals with cookies, such as persisting a session and saving / destroying a session.
    module Cookies
      def self.included(klass)
        klass.after_save :save_cookie, :if => :persisting?
        klass.after_destroy :destroy_cookie, :if => :persisting?
      end
      
      # Tries to validate the session from information in the cookie
      def valid_cookie?
        if cookie_credentials
          self.unauthorized_record = search_for_record("find_by_#{persistence_token_field}", cookie_credentials)
          return valid?
        end
        
        false
      end
      
      private
        def cookie_credentials
          controller.cookies[cookie_key]
        end
        
        def save_cookie
          
          expires = nil
          if controller.params && controller.params[:user_session] && controller.params[:user_session][:remember_me] && controller.params[:user_session][:remember_me] == "1"
            expires = Time.now + 3.months
          elsif controller.cookies && controller.cookies[:r] && controller.cookies[:r] == "1"
            expires = Time.now + 3.months
            controller.cookies[:r] = { :value => "1", :expires => (Time.now - 999) }
          end
  
          controller.cookies[cookie_key] = {
            :value => record.send(persistence_token_field),
            :expires => (expires)
          }
        end
        
        def destroy_cookie
          controller.cookies.delete cookie_key
        end
    end
  end
end
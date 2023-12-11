module DAV4Rack
  module CardDAV
    class Resource < DAV4Rack::Resource
      def get_property(element)
        case element[:name]
        when "current-user-privilege-set"
          current_user_privilege_set
        when "group"
          ""
        when "owner"
          owner
        else          
          super
        end
      end

      private

      def current_user_privilege_set
        
      end

      def acl_restrictions
        
      end

      def owner
        @options[:root_uri_path]
      end
    end
  end
end

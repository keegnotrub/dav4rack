module DAV4Rack
  module CardDAV
    class PrincipalResource < Resource
      def collection?
        true
      end

      def children
        []
      end

      def exist?
        path == ""
      end

      def get_property(element)
        case element[:name]
        when "current-user-principal"
          @options[:root_uri_path]
        when "principal-URL"
          @options[:root_uri_path]
        when "acl"
          acl
        when "acl-restrictions"
          acl_restrictions
        when "displayname"
          "Principal Resource"
        when "creationdate"
          Time.now
        when "getlastmodified"
          Time.now
        when "resourcetype"
          [ :collection, :principal ]
        else
          super
        end
      end

      private

      def acl
        
      end

      def acl_restrictions
        
      end
    end
  end
end

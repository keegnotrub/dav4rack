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
        when "principal-URL"
          URI.parse(@options[:root_uri_path])
        when "current-user-principal"
          URI.parse(@options[:root_uri_path])
        when "acl"
          acl
        when "acl-restrictions"
          [ :"grant-only", :"no-invert" ]
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
        render_xml(:acl) do |xml|
          xml.ace do
            xml.principal do
              xml.href @options[:root_uri_path]
            end
            xml.protected
            xml.grant do
              xml.privilege "read"
              xml.privilege "read-acl"
              xml.privilege "read-current-user-privilege-set"
            end
          end
        end
      end
    end
  end
end

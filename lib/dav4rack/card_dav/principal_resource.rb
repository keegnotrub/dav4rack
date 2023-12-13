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
        when "addressbook-home-set"
          addressbook_home_set
        when "principal-address"
          principal_address
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
              PRIVILEGES.each do |privilege|
                xml.privilege do
                  xml.send(privilege)
                end
              end
            end
          end
        end
      end

      def addressbook_home_set
        render_xml(:"addressbook-home-set", CARDDAV_XML_NAMESPACES) do |xml|
          xml.href @options[:home_set_path]
        end
      end

      def principal_address
        render_xml(:"principal-address", CARDDAV_XML_NAMESPACES) do |xml|
          # TODO
          # xml.href current_user_vcard_url
        end
      end
    end
  end
end

module DAV4Rack
  module CardDAV
    class Resource < DAV4Rack::Resource
      PRIVILEGES = ["read", "read-acl", "read-current-user-privilege-set"].freeze
      WEBDAV_XML_NAMESPACES = {'xmlns:D' => 'DAV:'}.freeze
      CARDDAV_XML_NAMESPACES = {'xmlns:C' => 'urn:ietf:params:xml:ns:carddav:', 'xmlns:D' => 'DAV:'}.freeze
      
      def get_property(element)
        case element[:name]
        when "current-user-privilege-set"
          current_user_privilege_set
        when "group"
          ""
        when "owner"
          URI.parse(@options[:root_uri_path])
        else          
          super
        end
      end

      protected

      def render_xml(root_type, xml_attributes = WEBDAV_XML_NAMESPACES)
        Nokogiri::XML::Builder.new do |xml_base|
          xml_base.send(root_type.to_s, xml_attributes.merge(root_xml_attributes)) do
            xml_base.parent.namespace = xml_base.parent.namespace_definitions.first
            xml = xml_base['D']
            yield xml
          end            
        end.doc.root
      end

      private

      def current_user_privilege_set
        render_xml(:"current-user-privilege-set") do |xml|
          PRIVILEGES.each do |privilege|
            xml.privilege do
              xml.send(privilege)
            end
          end
        end
      end
    end
  end
end

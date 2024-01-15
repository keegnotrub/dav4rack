module DAV4Rack
  module CardDAV
    class AddressBookResource < Resource
      def collection?
        true
      end

      def children
        contact_ids.map do |id|
          child(id.to_s)
        end
      end

      def contact_ids
        []
      end

      def exist?
        path == "default"
      end

      def child_resource
        ContactResource
      end

      def parent_resource
        HomeSetResource
      end

      def get_property(element)
        case element[:name]
        when "supported-report-set"
          supported_report_set
        when "supported-collation-set"
          supported_collation_set
        when "supported-address-data"
          supported_address_data
        when "addressbook-description"
          address_book_description
        else
          super
        end
      end

      def creation_date
        Time.now
      end

      def last_modified
        Time.now
      end

      def content_type
        "httpd/unix-directory"
      end

      def resource_type
        render_xml(:resourcetype) do |xml|
          xml.collection
          xml.addressbook(CARDDAV_XML_NAMESPACES) do
            xml.parent.namespace = xml.parent.namespace_definitions.first
          end
        end
      end

      private

      def supported_report_set
        render_xml(:"supported-report-set") do |xml|
          xml.report do
            xml.send(:"addressbook-multiget", CARDDAV_XML_NAMESPACES) do
              xml.parent.namespace = xml.parent.namespace_definitions.first
            end
            xml.send(:"addressbook-query", CARDDAV_XML_NAMESPACES) do
              xml.parent.namespace = xml.parent.namespace_definitions.first
            end
          end
        end
      end

      def supported_collation_set
        render_xml(:"supported-collation-set", CARDDAV_XML_NAMESPACES) do |xml|
          xml.send(:"supported-collation", CARDDAV_XML_NAMESPACES) do |xml|
            xml.parent.namespace = xml.parent.namespace_definitions.first
            xml.text "i;ascii-casemap"
          end
          xml.send(:"supported-collation", CARDDAV_XML_NAMESPACES) do |xml|
            xml.parent.namespace = xml.parent.namespace_definitions.first
            xml.text "i;unicode-casemap"
          end
        end
      end

      def supported_address_data
        render_xml(:"supported-address-data", CARDDAV_XML_NAMESPACES) do |xml|
          xml.send(:"address-data-type", CARDDAV_XML_NAMESPACES.merge("content-type" => "text/vcard", "version" => "3.0")) do |xml|
            xml.parent.namespace = xml.parent.namespace_definitions.first
          end
        end 
      end

      def address_book_description
        render_xml(:"addressbook-description", CARDDAV_XML_NAMESPACES) do |xml|
          xml.text name
        end
      end
    end
  end
end

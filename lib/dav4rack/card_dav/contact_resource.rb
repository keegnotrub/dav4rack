module DAV4Rack
  module CardDAV
    class ContactResource < Resource
      def collection?
        false
      end

      def vcard_fields
        []
      end

      def exist?
        true
      end

      def parent_resource
        AddressBookResource
      end

      def get_property(element)
        case element[:name]
        when "address-data"
          address_data(element)
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
        "text/vcard"
      end

      def vcard
        lines = []
        lines << "BEGIN:VCARD"
        lines << "VERSION:3.0"

        vcard_fields.each do |field, value|
          lines << "#{field}:#{value}"
        end

        lines << "END:VCARD\n"
        lines.compact.join("\n")
      end

      def address_data(element)
        render_xml(:"address_data", CARDDAV_NAMESPACES) do |xml|
          xml.text vcard
        end
      end
    end
  end
end

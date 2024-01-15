module DAV4Rack
  module CardDAV
    class HomeSetResource < Resource
      def collection?
        true
      end

      def children
        [child("default")]
      end

      def exist?
        true
      end

      def child_resource
        AddressBookResource
      end
    end
  end
end

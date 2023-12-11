module DAV4Rack
  module CardDAV
    class Controller < DAV4Rack::Controller
      def report
        unless resource.exist?
          return NotFound
        end

        if request_document.nil? or request_document.root.nil?
          render_xml(:error) do |xml|
            xml.send :"empty-request"
          end
          raise BadRequest
        end

        case request_document.root.name
        when "addressbook-multiget"
          addressbook_multiget(request_document)
        when "addressbook-query"
          addressbook_query(request_document)
        else
          render_xml(:error) do |xml|
            xml.send :"supported-report"
          end
          raise Forbidden
        end        
      end
      
      private

      def addressbook_query(request_document)
        # TODO
      end

      def addressbook_multiget(request_document)
        # TODO
      end
    end
  end
end

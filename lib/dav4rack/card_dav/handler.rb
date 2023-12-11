require 'dav4rack/logger'

module DAV4Rack
  module CardDAV
    class Handler < DAV4Rack::Handler
      DAV_EXTENSIONS = ["access-control", "addressbook"].freeze
      
      def initialize(options={})
        @options = options.dup
        unless(@options[:dav_extensions])
          @options[:dav_extensions] = DAV_EXTENSIONS
        end
        unless(@options[:controller_class])
          @options[:controller_class] = Controller
        end
        Logger.set(*@options[:log_to])
      end
    end
  end
end

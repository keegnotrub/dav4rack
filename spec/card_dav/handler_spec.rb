require "spec_helper"
require "dav4rack/card_dav"
require "debug"

RSpec.describe DAV4Rack::CardDAV::Handler do
  METHODS = %w(GET PUT POST DELETE PROPFIND PROPPATCH MKCOL COPY MOVE OPTIONS HEAD LOCK UNLOCK)  
  
  attr_reader :response

  before do
    @controller = DAV4Rack::CardDAV::Handler.new(
      root_uri_path: "/",
      resource_class: DAV4Rack::CardDAV::PrincipalResource,
      home_set_path: "/books/"
    )
  end
  
  def request(method, uri, options={})
    options = {
      'HTTP_HOST' => 'localhost',
      'REMOTE_USER' => 'user'
    }.merge(options)
    request = Rack::MockRequest.new(@controller)
    @response = request.request(method, uri, options)
  end

  METHODS.each do |method|
    define_method(method.downcase) do |*args|
      request(method, *args)
    end
  end  
  
  def render(root_type)
    raise ArgumentError.new 'Expecting block' unless block_given?
    doc = Nokogiri::XML::Builder.new do |xml_base|
      xml_base.send(root_type.to_s, 'xmlns:D' => 'DAV:') do
        xml_base.parent.namespace = xml_base.parent.namespace_definitions.first
        xml = xml_base['D']
        yield xml
      end
    end
    doc.to_xml
  end
 
  def response_xml
    Nokogiri.XML(@response.body)
  end
  
  def propfind_xml(*props)
    render(:propfind) do |xml|
      xml.prop do
        props.each do |prop|
          xml.send(prop)
        end
      end
    end
  end

  describe '[4] Principal Properties' do
    it '[4.2] DAV:principal-URL' do
      propfind('/', :input => propfind_xml(:"principal-URL"))
      expect(@response).not_to be_empty
    end
  end
end

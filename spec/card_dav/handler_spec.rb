require "spec_helper"
require "dav4rack/card_dav"
require "debug"

RSpec.describe DAV4Rack::CardDAV::Handler do
  METHODS = %w(GET PUT POST DELETE PROPFIND PROPPATCH MKCOL COPY MOVE OPTIONS HEAD LOCK UNLOCK REPORT)
  
  attr_reader :response

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

  def multistatus_response(pattern)
    expect(@response).to be_multi_status
    expect(response_xml.xpath('//D:multistatus/D:response', response_xml.root.namespaces)).not_to be_empty
    response_xml.xpath("//D:multistatus/D:response#{pattern}", response_xml.collect_namespaces)
  end

  def carddav_propfind_xml(prop)
    render(:propfind) do |xml|
      xml.prop do
        xml.send(prop, {'xmlns:C' => 'urn:ietf:params:xml:ns:carddav:'}) do
          xml.parent.namespace = xml.parent.namespace_definitions.first
        end
      end
    end
  end

  def propfind_xml(prop, carddav: false)
    render(:propfind) do |xml|
      xml.prop do
        xml.send(prop)
      end
    end
  end

  context "RFC 3744: WebDav Access Control Protocol" do
    before do
      @controller = DAV4Rack::CardDAV::Handler.new(
        root_uri_path: "/",
        resource_class: DAV4Rack::CardDAV::PrincipalResource
      )
    end
    
    describe '[4] Principal Properties' do
      it '[4.2] DAV:principal-URL' do
        propfind('/', :input => propfind_xml(:"principal-URL"))
        expect(multistatus_response("/D:propstat/D:prop/D:principal-URL/D:href").first.text).to eq('/')
      end
    end

    describe '[5] Access Control Properties' do
      it '[5.1]  DAV:owner' do
        propfind('/', :input => propfind_xml(:owner))
        expect(multistatus_response("/D:propstat/D:prop/D:owner/D:href").first.text).to eq('/')
      end

      it '[5.2] DAV:group' do
        propfind('/', :input => propfind_xml(:group))
        expect(multistatus_response("/D:propstat/D:prop/D:group").first.text).to eq('')
      end

      it '[5.4] DAV:current-user-privilege-set' do
        propfind('/', :input => propfind_xml(:"current-user-privilege-set"))
        expect(multistatus_response("/D:propstat/D:prop/D:current-user-privilege-set/D:privilege/D:read")).not_to be_empty
        expect(multistatus_response("/D:propstat/D:prop/D:current-user-privilege-set/D:privilege/D:read-acl")).not_to be_empty
        expect(multistatus_response("/D:propstat/D:prop/D:current-user-privilege-set/D:privilege/D:read-current-user-privilege-set")).not_to be_empty
      end

      describe '[5.5] DAV:acl' do
        it '[5.5.1] ACE Principal' do
          propfind('/', :input => propfind_xml(:acl))
          expect(multistatus_response("/D:propstat/D:prop/D:acl/D:ace/D:principal/D:href").first.text).to eq('/')
        end
        it '[5.5.2] ACE Grant and Deny' do
          propfind('/', :input => propfind_xml(:acl))
          expect(multistatus_response("/D:propstat/D:prop/D:acl/D:ace/D:grant/D:privilege/D:read")).not_to be_empty
          expect(multistatus_response("/D:propstat/D:prop/D:acl/D:ace/D:grant/D:privilege/D:read-acl")).not_to be_empty
          expect(multistatus_response("/D:propstat/D:prop/D:acl/D:ace/D:grant/D:privilege/D:read-current-user-privilege-set")).not_to be_empty
        end
      end

      describe '[5.6] DAV:acl-restrictions' do
        it '[5.6.1] DAV:grant-only' do
          propfind('/', :input => propfind_xml(:"acl-restrictions"))
          expect(multistatus_response("/D:propstat/D:prop/D:acl-restrictions/D:grant-only")).not_to be_empty
        end
        it '[5.6.2] DAV:no-invert' do
          propfind('/', :input => propfind_xml(:"acl-restrictions"))
          expect(multistatus_response("/D:propstat/D:prop/D:acl-restrictions/D:no-invert")).not_to be_empty
        end
      end
    end

    describe "[7] Access Control Feature" do
      it "[7.2] Access Control Support" do
        expect(options("/")).to be_ok
        expect(response.headers["Dav"]).to include("access-control")
      end
    end
  end

  context "RFC 5397: WebDAV Current Principal Extension" do
    before do
      @controller = DAV4Rack::CardDAV::Handler.new(
        root_uri_path: "/",
        resource_class: DAV4Rack::CardDAV::PrincipalResource
      )
    end
    
    it "[3] DAV:current-user-principal" do
      propfind('/', :input => propfind_xml(:"current-user-principal"))
      expect(multistatus_response("/D:propstat/D:prop/D:current-user-principal/D:href").first.text).to eq('/')
    end
  end

  context "RFC 6352: CardDAV" do
    describe "[6] Address Book Feature" do
      before do
        @controller = DAV4Rack::CardDAV::Handler.new(
          root_uri_path: "/lists/",
          resource_class: DAV4Rack::CardDAV::AddressBookResource,
        )
      end
      
      it "[6.1] Address Book Support" do
        expect(options("/")).to be_ok
        expect(response.headers["Dav"]).to include("addressbook")
      end

      it "[6.2.1] CARDDAV:addressbook-description" do
        propfind('/lists/default', :input => carddav_propfind_xml(:"addressbook-description"))
        expect(multistatus_response("/D:propstat/D:prop/C:addressbook-description").first.text).to eq('default')
      end

      it "[6.2.2] CARDAV:supported-address-data" do
        propfind('/lists/default', :input => carddav_propfind_xml(:"supported-address-data"))
        expect(multistatus_response("/D:propstat/D:prop/C:supported-address-data/C:address-data-type")).not_to be_empty
      end
    end

    describe "[7] Address Book Access Control" do
      before do
        @controller = DAV4Rack::CardDAV::Handler.new(
          root_uri_path: "/",
          resource_class: DAV4Rack::CardDAV::PrincipalResource,
        )
      end
      
      it "[7.1.1] CARDDAV:addressbook-home-set" do
        propfind('/', :input => carddav_propfind_xml(:"addressbook-home-set"))
        expect(multistatus_response("/D:propstat/D:prop/C:addressbook-home-set/D:href").first.text).to eq('/lists/')
      end

      it "[7.1.2] CARDDAV:principal-address" do        
        propfind('/', :input => carddav_propfind_xml(:"principal-address"))
        expect(multistatus_response("/D:propstat/D:prop/C:principal-address/D:unauthenticated")).not_to be_empty
      end
    end

    describe "[8] Address Book Reports" do
      before do
        @controller = DAV4Rack::CardDAV::Handler.new(
          root_uri_path: "/lists/",
          resource_class: DAV4Rack::CardDAV::AddressBookResource,
        )
      end

      it "[8.3.1] CARDDAV:supported-collation-set" do
        propfind('/lists/default', :input => carddav_propfind_xml(:"supported-collation-set"))
        expect(multistatus_response("/D:propstat/D:prop/C:supported-collation-set/C:supported-collation").map(&:text)).to match(['i;ascii-casemap', 'i;unicode-casemap'])
      end

      it "[8.6] CARDDAV:addressbook-query" do
        # TODO
        # report('/lists/default', :input => carddav_report_xml(:"addressbook-query"))
        # @response.body
      end

      it "[8.7] CARDDAV:addressbook-multiget" do
        # TODO
        # report('/lists/default', :input => carddav_report_xml(:"addressbook-multiget"))
        # @response.body
      end
    end
  end

  context "RFC 3253: Versioning Extensions to WebDAV" do
    describe "[3] Version-Control Feature" do
      before do
        @controller = DAV4Rack::CardDAV::Handler.new(
          root_uri_path: "/lists/",
          resource_class: DAV4Rack::CardDAV::AddressBookResource,
        )
      end

      it "[3.1.5] DAV:supported-report-set" do
        propfind('/lists/default', :input => propfind_xml(:"supported-report-set"))
        expect(multistatus_response("/D:propstat/D:prop/D:supported-report-set/D:report/C:addressbook-multiget")).not_to be_empty
        expect(multistatus_response("/D:propstat/D:prop/D:supported-report-set/D:report/C:addressbook-query")).not_to be_empty
      end
    end
  end
end

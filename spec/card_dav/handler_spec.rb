require "spec_helper"
require "dav4rack/card_dav"
require "debug"

RSpec.describe DAV4Rack::CardDAV::Handler do
  METHODS = %w(GET PUT POST DELETE PROPFIND PROPPATCH MKCOL COPY MOVE OPTIONS HEAD LOCK UNLOCK)  
  
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
        resource_class: DAV4Rack::CardDAV::PrincipalResource,
        home_set_path: "/books/"
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
  end

  context "RFC 5397: WebDAV Current Principal Extension" do
    before do
      @controller = DAV4Rack::CardDAV::Handler.new(
        root_uri_path: "/",
        resource_class: DAV4Rack::CardDAV::PrincipalResource,
        home_set_path: "/books/"
      )
    end
    
    it "[3] DAV:current-user-principal" do
      propfind('/', :input => propfind_xml(:"current-user-principal"))
      expect(multistatus_response("/D:propstat/D:prop/D:current-user-principal/D:href").first.text).to eq('/')
    end
  end

  context "RFC 6352: CardDAV" do
    before do
      @controller = DAV4Rack::CardDAV::Handler.new(
        root_uri_path: "/",
        resource_class: DAV4Rack::CardDAV::PrincipalResource,
        home_set_path: "/books/"
      )
    end

    describe "[6] Address Book Feature" do
      it "[6.1] Address Book Support" do
        expect(options("/")).to be_ok
        expect(response.headers["Dav"]).to include("addressbook")
      end
    end

    describe "[7] Address Book Access Control" do
      it "[7.1.1] CARDDAV:addressbook-home-set" do
        propfind('/', :input => carddav_propfind_xml(:"addressbook-home-set"))
        expect(multistatus_response("/D:propstat/D:prop/C:addressbook-home-set/D:href").first.text).to eq('/books/')
      end

      it "[7.1.2] CARDDAV:principal-address" do        
        propfind('/', :input => carddav_propfind_xml(:"principal-address"))
        expect(multistatus_response("/D:propstat/D:prop/C:principal-address")).not_to be_empty
      end
    end
  end
end

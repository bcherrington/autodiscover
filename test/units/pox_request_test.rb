require 'test_helper'
require 'ostruct'

describe Autodiscover::PoxRequest do
  let(:_class) { Autodiscover::PoxRequest }
  let(:http) { mock('http') }
  let(:client) { OpenStruct.new({ http: http, domain: 'example.local', email: 'test@example.local' }) }

  describe '#autodiscover' do
    it 'returns a PoxResponse if the autodiscover is successful' do
      request_body = <<-EOF.gsub(/^        /, '')
        <?xml version="1.0"?>
        <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
          <Request>
            <EMailAddress>test@example.local</EMailAddress>
            <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
          </Request>
        </Autodiscover>
      EOF
      http.expects(:post).with(
          'https://example.local/autodiscover/autodiscover.xml', request_body,
          { 'Content-Type' => 'text/xml; charset=utf-8' }
      ).returns(OpenStruct.new({ status: 200, body: <<-EOF.gsub(/^        /, '')
        <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
          <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
            <User>
              <DisplayName>First Last</DisplayName>
              <LegacyDN>/o=example/ou=First Administrative Group/cn=Recipients/cn=iuser885646</LegacyDN>
              <DeploymentId>644560b8-a1ce-429c-8ace-23395843f701</DeploymentId>
            </User>
            <Account>
              <AccountType>email</AccountType>
              <Action>settings</Action>
              <Protocol>
                <Type>EXCH</Type>
                <Server>MBX-SERVER.mail.internal.example.local</Server>
                <ServerDN>/o=example/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Configuration/cn=Servers/cn=MBX-SERVER</ServerDN>
                <ServerVersion>72008287</ServerVersion>
                <MdbDN>/o=example/ou=Exchange Administrative Group (FYDIBOHF23SPDLT)/cn=Configuration/cn=Servers/cn=MBX-SERVER/cn=Microsoft Private MDB</MdbDN>
                <ASUrl>https://mail.example.local/ews/exchange.asmx</ASUrl>
                <OOFUrl>https://mail.example.local/ews/exchange.asmx</OOFUrl>
                <UMUrl>https://mail.example.local/unifiedmessaging/service.asmx</UMUrl>
                <OABUrl>https://mail.example.local/OAB/d29844a9-724e-468c-8820-0f7b345b767b/</OABUrl>
              </Protocol>
              <Protocol>
                <Type>EXPR</Type>
                <Server>Exchange.example.local</Server>
                <ASUrl>https://mail.example.local/ews/exchange.asmx</ASUrl>
                <OOFUrl>https://mail.example.local/ews/exchange.asmx</OOFUrl>
                <UMUrl>https://mail.example.local/unifiedmessaging/service.asmx</UMUrl>
                <OABUrl>https://mail.example.local/OAB/d29844a9-724e-468c-8820-0f7b345b767b/</OABUrl>
              </Protocol>
              <Protocol>
                <Type>WEB</Type>
                <Internal>
                  <OWAUrl AuthenticationMethod="Ntlm, WindowsIntegrated">https://cas-01-server.mail.internal.example.local/owa</OWAUrl>
                  <OWAUrl AuthenticationMethod="Ntlm, WindowsIntegrated">https://cas-02-server.mail.internal.example.local/owa</OWAUrl>
                  <OWAUrl AuthenticationMethod="Basic">https://cas-04-server.mail.internal.example.local/owa</OWAUrl>
                  <OWAUrl AuthenticationMethod="Ntlm, WindowsIntegrated">https://cas-05-server.mail.internal.example.local/owa</OWAUrl>
                </Internal>
              </Protocol>
            </Account>
          </Response>
        </Autodiscover>
      EOF
                               }))
      # ).returns(OpenStruct.new({ status: 200, body: '<Autodiscover><Response><test></test></Response></Autodiscover>' }))

      inst = _class.new(client)
      _(inst.autodiscover).must_be_instance_of(Autodiscover::PoxResponse)
    end

    it 'will fail if :ignore_ssl_errors is not true' do
      http.expects(:post).raises(OpenSSL::SSL::SSLError, 'Test Error')
      inst = _class.new(client)
      -> { inst.autodiscover }.must_raise(OpenSSL::SSL::SSLError)
    end

    it 'keeps trying if :ignore_ssl_errors is set' do
      http.expects(:get).times(2).returns(OpenStruct.new({ headers: { 'Location' => 'http://example.local' }, status: 302 }))
      http.expects(:post).times(4).
          raises(OpenSSL::SSL::SSLError, 'Test Error').then.
          raises(OpenSSL::SSL::SSLError, 'Test Error').then.
          raises(Errno::ENETUNREACH, 'Test Error')
      inst = _class.new(client, ignore_ssl_errors: true)
      _(inst.autodiscover).must_be_nil
    end

    # TODO add redirect_addr and redirect_url tests
    # TODO add error response handling tests
    # TODO add dns lookup tests

  end
end

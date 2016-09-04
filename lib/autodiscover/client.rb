module Autodiscover
  class Client

    attr_reader :domain, :email, :http

    # @param email [String] An e-mail to use for autodiscovery. It will be
    #   used as the default username.
    # @param password [String]
    # @param username [String] An optional username if you want to authenticate
    #   with something other than the e-mail. For instance DOMAIN\user
    # @param domain [String] An optional domain to provide as an override for
    #   the one parsed from the e-mail.
    def initialize(email:, password:, username: nil, domain: nil)
      @email    = email
      @domain   = domain || @email.split('@').last
      @http     = HTTPClient.new
      @username = username || email
      @http.set_auth(nil, @username, password)
      # TODO make these files & locations configurable
      @http.ssl_config.add_trust_ca('/etc/pki/tls/certs/ca-bundle.crt')
      @http.ssl_config.add_trust_ca('/etc/pki/tls/certs/ca-bundle.trust.crt')
    end

    # @param type [Symbol] The type of response. Right now this is just :pox
    # @param [Hash] **options
    def autodiscover(type: :pox, **options)
      case type
        when :pox
          PoxRequest.new(self, **options).autodiscover
        when :soap
          raise NotImplementedError, 'The SOAP autodiscover type is not implemented.'
        else
          raise Autodiscover::ArgumentError, "Not a valid autodiscover type (#{type})."
      end
    end

  end
end

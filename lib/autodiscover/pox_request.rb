require 'resolv'

module Autodiscover
  class PoxRequest
    include Autodiscover

    attr_reader :client, :options

    # @param client [Autodiscover::Client]
    # @param [Hash] **options
    # @option **options [Boolean] :ignore_ssl_errors Whether to keep trying if
    #   there are SSL errors
    def initialize(client, **options)
      @client          = client
      @options         = options
      @domain          = client.domain
      logger.appenders = Logging.appenders.file('autodiscover.log')
    end

    # @return [Autodiscover::PoxResponse, nil]
    def autodiscover(domain = @domain)
      xml_response = nil
      available_urls(domain) do |url|
        xml_response = do_request url
        break unless xml_response.nil?
      end
      xml_response
    end

    private
    def do_request(url)
      xml_response = nil
      begin
        response = client.http.post(url, request_body, { 'Content-Type' => 'text/xml; charset=utf-8' })
        logger.debug "#{url} response status #{response.status}"
        case response
          when Success
            xml_response = PoxResponse.new(response.body)
            xml_response = autodiscover(xml_response.redirect_url) if xml_response.redirect_addr?
            xml_response = do_request(xml_response.redirect_url) if xml_response.redirect_url?
          when Redirect
            xml_response = autodiscover(response.headers['Location'])
          else
            xml_response = nil
        end
      rescue Errno::ENETUNREACH => e
        logger.debug "#{url} Errno::ENETUNREACH"
        logger.debug e.message
        xml_response = nil
      rescue Errno::ECONNREFUSED => e
        logger.debug "#{url} Errno::ECONNREFUSED"
        logger.debug e.message
        xml_response = nil
      rescue OpenSSL::SSL::SSLError => e
        logger.debug "#{url} OpenSSL::SSL::SSLError"
        logger.debug e.message
        options[:ignore_ssl_errors] ? (xml_response = nil) : raise
      end
      xml_response
    end

    def good_response?(response)
      response.status == 200
    end

    def redirect_response(response)
      response.status == 301 || response.status == 302
    end

    class Success
      def self.===(item)
        item.status >= 200 && item.status < 300
      end
    end

    class Redirect
      def self.===(item)
        item.status == 301 || item.status == 302
      end
    end

    class Empty
      def self.===(item)
        item.response_size == 0
      end
    end

    def available_urls(domain, &block)
      return to_enum(__method__, domain) unless block_given?

      formatted_https_urls(domain).each do |url|
        logger.debug "Yielding HTTPS Url #{url}"
        yield url
      end

      yield redirected_http_url(domain)

      Resolv::DNS.new.each_resource("_autodiscover._tcp.#{domain}", Resolv::DNS::Resource::IN::SRV) do |entry|
        formatted_https_urls(entry.target).each do |url|
          logger.debug "Yielding SRV HTTPS Url #{url}"
          yield url
        end
      end
    end

    def formatted_https_urls(domain)
      %W{
        https://#{domain}/autodiscover/autodiscover.xml
        https://autodiscover.#{domain}/autodiscover/autodiscover.xml
      }
    end

    def redirected_http_url(domain)
      response = client.http.get("http://autodiscover.#{domain}/autodiscover/autodiscover.xml")
      logger.debug "Yielding HTTP Redirected Url #{(redirect_response(response)) ? response.headers['Location'] : nil}"
      (redirect_response(response)) ? response.headers['Location'] : nil
    end

    def request_body
      Nokogiri::XML::Builder.new do |xml|
        xml.Autodiscover('xmlns' => 'http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006') {
          xml.Request {
            xml.EMailAddress client.email
            xml.AcceptableResponseSchema 'http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a'
          }
        }
      end.to_xml
    end

  end
end

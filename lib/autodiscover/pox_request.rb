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
      @client  = client
      @options = options
      @domain  = client.domain
    end

    # @return [Autodiscover::PoxResponse, nil]
    def autodiscover(domain = @domain)
      response = nil
      available_urls(domain) do |url|
        response = do_request url
        break unless response.nil?
      end

      response.nil? ? PoxFailedResponse.new(0, 'Unknown error occured. Autodiscovery failed.') : response


    end

    private

    def do_request(url)
      response = nil
      begin
        http_response = client.http.post(url, request_body, { 'Content-Type' => 'text/xml; charset=utf-8' })
        logger.debug "#{url} response status #{http_response.status}"
        case http_response
          when Success
            response = PoxResponse.new(http_response.body)
            response = autodiscover(response.redirect_url) if response.redirect_addr?
            response = do_request(response.redirect_url) if response.redirect_url?
          when Redirect
            response = autodiscover(http_response.headers['Location'])
          when InvalidRequest
            response = nil
          when InvalidCredentials
            response = PoxFailedResponse.new(401, 'Incorrect login credentials')
          else
            response = http_response
        end
      rescue SocketError => e
        logger.debug "#{url} SocketError"
        logger.debug e.message
        e.message.include?('No such host is known.') ? response = PoxFailedResponse.new(1, 'Unknown host. Ensure domain is correct') : response = PoxFailedResponse.new(1, e.message)
      rescue HTTPClient::ConnectTimeoutError => e
        logger.debug "#{url} HTTPClient::ConnectTimeoutError"
        logger.debug e.message
        response = nil
      rescue Errno::ENETUNREACH => e
        logger.debug "#{url} Errno::ENETUNREACH"
        logger.debug e.message
        response = nil
      rescue Errno::ECONNREFUSED => e
        logger.debug "#{url} Errno::ECONNREFUSED"
        logger.debug e.message
        response = PoxFailedResponse.new(2, e.message)
      rescue OpenSSL::SSL::SSLError => e
        logger.debug "#{url} OpenSSL::SSL::SSLError"
        logger.debug e.message
        options[:ignore_ssl_errors] ? (response = nil) : raise
      end
      response.nil? ? logger.debug("#{url} returned nil response") : logger.debug("#{url} xml_response: #{response}")
      response
    end

    def good_response?(response)
      response.status == 200
    end

    def redirect_response?(response)
      response == Redirect
    end

    class Success
      def self.===(item)
        item.status >= 200 && item.status < 300
      end
    end

    class Redirect
      def self.===(item)
        item.status == 301 || item.status == 302 || item.status == 307 || item.status == 308
      end
    end

    class InvalidRequest
      def self.===(item)
        item.status == 400 || item.status == 404 || item.status == 405 || item.status == 406
      end
    end

    class InvalidCredentials
      def self.===(item)
        item.status == 401
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

      formatted_https_urls(domain).each do |url|
        http_uri        = URI.parse(url)
        http_uri.scheme = 'http'
        logger.debug "Yielding HTTP Url for redirect #{http_uri}"
        yield redirected_http_url(http_uri)
      end

      Resolv::DNS.new.each_resource("_autodiscover._tcp.#{domain}", Resolv::DNS::Resource::IN::SRV) do |entry|
        formatted_https_urls(entry.target).each do |url|
          logger.debug "Yielding SRV HTTPS Url #{url}"
          yield url
        end
      end
    end

    def formatted_https_urls(domain)
      %W[
        https://#{domain}/autodiscover/autodiscover.xml
        https://autodiscover.#{domain}/autodiscover/autodiscover.xml
      ]
    end

    def redirected_http_url(url)
      begin
        # url      = "http://autodiscover.#{domain}/autodiscover/autodiscover.xml"
        response = client.http.get url
        logger.debug "Yielding HTTP Redirected Url #{redirect_response?(response) ? response.headers['Location'] : nil}"
        result = redirect_response?(response) ? response.headers['Location'] : nil
      rescue SocketError => e
        logger.debug "#{url} SocketError"
        logger.debug e.message
        result = nil
      rescue HTTPClient::ConnectTimeoutError => e
        logger.debug "#{url} HTTPClient::ConnectTimeoutError"
        logger.debug e.message
        result = nil
      rescue Errno::ECONNREFUSED => e
        logger.debug "#{url} Errno::ECONNREFUSED"
        logger.debug e.message
        result = nil
      rescue Errno::ENETUNREACH => e
        logger.debug "#{url} Errno::ENETUNREACH"
        logger.debug e.message
        result = nil
      end
      result
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

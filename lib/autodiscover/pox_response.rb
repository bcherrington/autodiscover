module Autodiscover
  class PoxResponse
    attr_reader :response

    def initialize(response)
      raise Autodiscover::ArgumentError, 'Response must be an XML string' if response.nil? || response.empty?
      @response = Nori.new(parser: :nokogiri).parse(response)['Autodiscover']['Response']
    end

    def user_display_name
      @display_name ||= user['DisplayName'] || {}
    end

    def user
      response['User'] || {}
    end

    def exchange_version
      ServerVersionParser.new(exch_proto['ServerVersion']).exchange_version
    end

    def ews_url
      expr_proto['EwsUrl']
    end

    def settings?
      account['Action'] == 'settings'
    end

    def redirect?
      redirect_url? || redirect_addr?
    end

    def redirect_url?
      account['Action'] == 'redirectUrl'
    end

    def redirect_addr?
      account['Action'] == 'redirectAddr'
    end

    def exch_proto
      @exch_proto ||= (account['Protocol'].select { |p| p['Type'] == 'EXCH' }.first || {})
    end

    def exhttp_proto
      @exhttp_proto ||= (account['Protocol'].select { |p| p['Type'] == 'EXHTTP' }.first || {})
    end

    def expr_proto
      @expr_proto ||= (account['Protocol'].select { |p| p['Type'] == 'EXPR' }.first || {})
    end

    def web_proto
      @web_proto ||= (account['Protocol'].select { |p| p['Type'] == 'WEB' }.first || {})
    end

    def redirect_addr
      account['RedirectAddr'] || ''
    end

    def redirect_url
      account['RedirectUrl'] || ''
    end

    def account
      response['Account'] || {}
    end
  end
end

module Autodiscover
  class PoxFailedResponse < PoxResponse
    attr_reader :code, :message

    def initialize(code, message)
      @code = code
      @message = message
      @logger = Logging.logger[self.class.name]
    end

    def dump_details
      @logger.info "PoxFailedResponse: Code #{@code.to_s}, #{@message.to_s}"
    end

  end
end
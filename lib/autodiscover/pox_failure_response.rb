module Autodiscover
  class PoxFailedResponse < PoxResponse
    attr_reader :code, :message

    def initialize(code, message)
      @code = code
      @message = message
    end

  end
end
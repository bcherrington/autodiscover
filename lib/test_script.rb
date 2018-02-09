require 'autodiscover'

logger = Logging.logger['Testing script']

print 'Enter password [chronosync@chronologic.co.za]: '
pass = 'something_incorrect'

client = Autodiscover::Client.new(email: "chronosync@chronologic.co.za", password: pass)

data = client.autodiscover

# check for failure
if data.is_a? Autodiscover::PoxFailedResponse
  logger.info "Failed response received with code #{data.code}: #{data.message}"
end


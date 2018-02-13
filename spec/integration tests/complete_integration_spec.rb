require 'autodiscover'
require 'spec_helper'

@logger = Logging.logger['Integration testing']

feature 'User attempts to discover' do
  scenario 'when all details are correct' do

    email = 'chronosync@chronologic.co.za'
    password = '*censored'

    client = Autodiscover::Client.new(email: email, password: password)
    data = client.autodiscover
    data.dump_details

    expect(data).to be_a(Autodiscover::PoxResponse)
    expect(data).not_to be_a(Autodiscover::PoxFailedResponse)
  end

  scenario 'with incorrect credentials' do
    email = 'chronosync@chronologic.co.za'
    password = 'something_incorrect'

    client = Autodiscover::Client.new(email: email, password: password)
    data = client.autodiscover
    data.dump_details

    expect(data).to be_a(Autodiscover::PoxFailedResponse)

  end

  scenario 'to unknown host' do
    email = 'chronosync@chronologic.co.za'
    password = 'something'

    client = Autodiscover::Client.new(email: email, password: password, domain: 'chronologicunknown.co.za')
    data = client.autodiscover
    data.dump_details

    expect(data).to be_a(Autodiscover::PoxFailedResponse) and expect(data.message.include?('Unknown host')).to be true


  end

end


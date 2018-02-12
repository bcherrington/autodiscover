require 'autodiscover'
require 'spec_helper'

feature 'User attempts to discover' do
  scenario 'when all details are correct' do

    email = 'chronosync@chronologic.co.za'
    password = '*censored'

    client = Autodiscover::Client.new(email: email, password: password)
    data = client.autodiscover

    expect(data).to be_a(Autodiscover::PoxResponse)
    expect(data).not_to be_a(Autodiscover::PoxFailedResponse)
  end

  scenario 'with incorrect credentials' do

  end

  scenario 'to unknown host' do

  end

end


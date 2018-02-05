require 'autodiscover/version'
require 'nokogiri'
require 'nori'
require 'httpclient'
require 'logging'

#require 'debug'

module Autodiscover
  Logging.logger['Autodiscover'].level = :info

  # Logging.logger.root.level = :debug
  # Logging.color_scheme('bright',
  #                      lines: {
  #                          debug: :black,
  #                          info:  :bright_blue,
  #                          warn:  :yellow,
  #                          error: :red,
  #                          fatal: [:white, :on_red] })
  #
  # layout = Logging.layouts.pattern pattern:      "%d %-#{::Logging::MAX_LEVEL_LENGTH}l: [%c] %m\n",
  #                                  date_pattern: '%d-%m-%Y %H:%M:%S.%s',
  #                                  color_scheme: 'bright'
  # # Logging.logger.root.appenders = Logging.appenders.stdout layout: layout
  # Logging.logger.root.appenders = Logging.appenders.file('logs/autodiscover.log', layout: layout)
  #
  # Logging.logger.root.level                = :debug
  # Logging.logger['Autodiscover'].level     = :debug

  def self.logger
    Logging.logger['Autodiscover']
  end

  def logger
    @logger ||= Logging.logger[self.class.name]
  end
end

require 'autodiscover/defaults'
require 'autodiscover/errors'
require 'autodiscover/client'
require 'autodiscover/pox_request'
require 'autodiscover/pox_response'
require 'autodiscover/server_version_parser'

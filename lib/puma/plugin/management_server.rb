# frozen_string_literal: true

require 'puma/dsl'
require 'puma/plugin'
require 'bm/instrumentations'

Puma::DSL.include(Module.new do
  def management_server(port:, host: nil, logger: nil)
    @options[:management_server_port] = port
    @options[:management_server_host] = host if host
    @options[:management_server_logger] = logger if logger
  end
end)

Puma::Plugin.create do
  # @param launcher [Puma::Launcher]
  def start(launcher)
    port = launcher.options[:management_server_port] || 9000
    host = launcher.options[:management_server_host]
    logger = launcher.options[:management_server_logger]

    # @type [Puma::Events]
    events = launcher.events

    events.on_booted do
      server = BM::Instrumentations::Management::Server.run(port: port, host: host, logger: logger)
      events.on_stopped { server.shutdown }
    end
  end
end

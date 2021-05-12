# frozen_string_literal: true

require 'puma/dsl'
require 'puma/plugin'
require 'bm/instrumentations'

module BM
  module Instrumentations
    module Management
      # The {Puma::DSL} extension for configuring a management server
      #
      # @example config/puma.rb
      #   plugin(:management_server)
      #   management_server(port: 9000, host: '127.0.0.1', logger: SemanticLogger::Loggable['Management::Server'])
      module PumaDSL
        # Override the default {Server} configuration
        #
        # @param port [Integer] override a default port number that a server will listen to (default: 9990)
        # @param host [String, nil] override a default bind address that a server uses for
        #   listening (default: '0.0.0.0')
        # @param logger [Logger, nil] override a default logger (default: `Logger.new($stdout)`)
        # @param registry [Prometheus::Client::Registry] override a default registry
        def management_server(port: nil, host: nil, logger: nil, registry: nil)
          @options[:management_server_port] = port if port
          @options[:management_server_host] = host if host
          @options[:management_server_logger] = logger if logger
          @options[:management_server_registry] = registry if registry
        end
      end
    end
  end
end

Puma::DSL.include BM::Instrumentations::Management::PumaDSL

Puma::Plugin.create do
  # @param launcher [Puma::Launcher]
  def start(launcher)
    host = launcher.options[:management_server_host]
    port = launcher.options[:management_server_port]
    logger = launcher.options[:management_server_logger]
    registry = launcher.options[:management_server_registry]

    # @type [Puma::Events]
    events = launcher.events
    events.on_booted do
      server = BM::Instrumentations::Management::Server.run(port: port, host: host, logger: logger, registry: registry)
      events.on_stopped { server.shutdown }
    end
  end
end

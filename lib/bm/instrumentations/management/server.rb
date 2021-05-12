# frozen_string_literal: true

require 'rack'
require 'logger'
require 'puma'
require 'prometheus/client'
require 'prometheus/middleware/exporter'

module BM
  module Instrumentations
    module Management
      # @attr [String] host
      # @attr [Integer] port
      # @attr [Logger] logger
      # @attr [Prometheus::Client::Registry] registry
      class Server
        attr_reader :host, :port, :logger, :registry

        BACKLOG = 3
        THREADS = 1
        THREAD_NAME = 'management-server'
        SERVES = %w[/ping /metrics /gc-stats /threads].freeze

        # @param host [String] is a hostname to listen on
        # @param port [Integer] is a port to listen on
        # @param logger [Logger]
        # @param registry [Prometheus::Client::Registry]
        #
        # @api private
        def initialize(port:, host:, logger:, registry:)
          @host = host
          @port = port
          @logger = logger
          @registry = registry
        end
        private_class_method :new

        # Creates a management server backed by {Puma::Server} then bind and
        # listen to socket
        #
        # @param host [String, nil] is a hostname to listen on
        # @param port [Integer] is a port to listen on
        # @param logger [Logger, nil]
        # @param registry [Prometheus::Client::Registry, nil]
        #
        # @return [Running]
        def self.run(port:, host: nil, logger: nil, registry: nil)
          new(
            port: port,
            host: host || '127.0.0.1',
            logger: logger || ::Logger.new($stdout, progname: Server.class.name),
            registry: registry || ::Prometheus::Client.registry
          ).run
        end

        # Creates a management server backed by {Puma::Server} then bind and
        # listen to socket
        #
        # @return [Running]
        # @api private
        def run
          server = ::Puma::Server.new(rack_app, ::Puma::Events.stdio, puma_options)
          server.auto_trim_time = nil # disable trimming thread
          server.reaping_time = nil # disable reaping thread
          server.add_tcp_listener(host, port, _optimize_for_latency = true, _backlog = BACKLOG)

          Running.new(server, logger).tap { notify_started }
        end

        private

        # Writes log messages about just launched management server instance
        def notify_started
          logger.info(
            "Management server listen to http://#{host}:#{port}" \
            "[Puma/#{Puma::Server::VERSION}," \
            " threads:#{THREADS}," \
            " backlog:#{BACKLOG}]"
          )

          logger.info("Management serves #{SERVES.join(' ')}")
        end

        # @return [Hash<Symbol, Any>]
        def puma_options
          {
            min_threads: THREADS,  # uses a fixed sized thread pool
            max_threads: THREADS,  #
            queue_requests: false, # disable incoming requests buffering
            shutdown_debug: false  # for debugging reasons, may be enabled for testing
          }.freeze
        end

        # Builds a Rack application that serves requests to the management server
        #
        # @return [#call] a frozen rack application
        def rack_app
          ::Rack::ShowExceptions.new(
            ::Prometheus::Middleware::Exporter.new(ServeEndpoints.new, registry: registry)
          ).tap(&:freeze)
        end

        # Handles a running server instance
        #
        # @attr server [Puma::Server]
        # @attr logger [Logger]
        class Running
          attr_reader :server, :logger

          # @param server [Puma::Server]
          # @param logger [Logger]
          def initialize(server, logger)
            @server = server
            @logger = logger
            server.run(_background = true, thread_name: THREAD_NAME)
          end

          # Shutdowns and wait until the server finishes
          #
          # @return [nil]
          def shutdown
            server&.stop(_sync = true)
            @server = nil
            logger.info('Management server done')
          end
        end

        # Handles management requests such as /ping or /threads
        #
        # @api private
        class ServeEndpoints
          JSON_TEXT = { 'Content-Type' => 'application/json' }.freeze
          PLAIN_TEXT = { 'Content-Type' => 'text/plain' }.freeze
          PONG = [200, PLAIN_TEXT, ['pong']].freeze
          NOT_FOUND = [404, PLAIN_TEXT, ['not found']].freeze

          # @param env [Hash<String, Any>]
          # @return [(Integer, Hash<String, String>, Array<String>)]
          def call(env) # rubocop:disable Metrics/MethodLength
            return NOT_FOUND if env[::Rack::REQUEST_METHOD] != ::Rack::GET

            case env[::Rack::PATH_INFO]
            when '/ping'
              PONG
            when '/gc-stats'
              to_json(GC.stat)
            when '/threads'
              to_json(threads_list)
            else
              NOT_FOUND
            end
          end

          private

          # Returns a list of thread name and its backlog
          #
          # @return [Array<Hash<Symbol, String>>]
          def threads_list
            Thread.list.map { { name: _1.name, backtrace: _1.backtrace } }
          end

          # Converts value to JSON using Puma's generator
          #
          # @param value [Hash, Array]
          # @return [(Integer, Hash<String, String>, Array<String>)]
          def to_json(value)
            body = ::Puma::JSON.generate(value)
            [200, JSON_TEXT, [body]]
          end
        end
      end
    end
  end
end

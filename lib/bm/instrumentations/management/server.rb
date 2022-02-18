# frozen_string_literal: true

require 'rack'
require 'logger'
require 'puma'
require 'prometheus/client/formats/text'

module BM
  module Instrumentations
    # :nodoc:
    module Management
      PumaVersionError = Class.new(ArgumentError)
      MIN_PUMA_VERSION = '5.4.0'

      # Creates the management server backed by {Puma::Server} then bind and listen to.
      #
      # @param port [Integer] is a port number that a server will listen to (default: `9990`)
      # @param host [String] is a bind address that a server uses for listening (default: `0.0.0.0`)
      # @param logger [Logger, nil] is a logger instance for notifications (default: `Logger.new($stdout)`)
      # @param registry [Prometheus::Client::Registry, nil] override a default Prometheus registry
      #
      # @return [Server]
      def self.server(port: nil, host: nil, logger: nil, registry: nil)
        check_puma_version

        Server.new(
          port: port || 9990,
          host: host || '0.0.0.0',
          logger: logger || ::Logger.new($stdout, progname: Server.name),
          registry: registry || ::Prometheus::Client.registry
        )
      end

      # Ensures that the server run using puma > 5.4.0
      #
      # @raise [PumaVersionError]
      def self.check_puma_version
        return if Gem::Version.new(::Puma::Const::VERSION) >= Gem::Version.new(MIN_PUMA_VERSION)

        raise PumaVersionError, "#{name} requires puma version >= #{MIN_PUMA_VERSION}"
      end

      # The `management_server` provides monitoring and metrics on different HTTP port, it starts a separate
      # {Puma::Server} that serves requests.
      #
      # The server exposes few endpoints:
      # * `/ping` - a liveness probe, always return `HTTP 200 OK` when the server is running
      # * `/metrics` - metrics list from the current Prometheus registry
      # * `/gc-status` - print ruby GC statistics as JSON
      # * `/threads` - print running threads, names and backtraces as JSON
      #
      # @attr [String] host
      # @attr [Integer] port
      # @attr [Logger] logger
      # @attr [Prometheus::Client::Registry] registry
      # @attr [Puma::Events] events
      class Server
        attr_reader :host, :port, :logger, :registry, :events

        # The socket backlog value
        BACKLOG = 3

        # The number of worker threads for puma server
        THREADS = 1

        # The server's thread name
        THREAD_NAME = 'management-server'

        # List of served endpoints
        SERVES = %w[/ping /metrics /gc-stats /threads].freeze

        # @param host [String]
        # @param port [Integer]
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

        # Creates a management server backed by {Puma::Server} then bind and
        # listen to
        #
        # @return [Running]
        def run
          server = ::Puma::Server.new(rack_app, ::Puma::Events.null, puma_options)
          server.auto_trim_time = nil # disable trimming thread
          server.reaping_time = nil # disable reaping thread
          server.add_tcp_listener(host, port, _optimize_for_latency = true, _backlog = BACKLOG)

          Running.new(server, logger).tap { notify_started(_1) }
        end

        private

        # Writes log messages about just launched management server instance
        #
        # @param running [Running]
        def notify_started(running)
          logger.info(
            "Management server listen to http://#{host}:#{running.port}" \
            " [Puma/#{::Puma::Server::VERSION}" \
            " threads:#{THREADS}" \
            " backlog:#{BACKLOG}]"
          )

          logger.info("Management serves [#{SERVES.join(' ')}]")
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
          ::Rack::ShowExceptions.new(ServeEndpoints.new(registry)).freeze
        end

        # Handles a running server instance
        #
        # @attr server [Puma::Server]
        # @attr logger [Logger]
        # @attr port [Integer]
        class Running
          attr_reader :server, :logger, :port

          # @param server [Puma::Server]
          # @param logger [Logger]
          def initialize(server, logger)
            @server = server
            @port = server.connected_ports.first
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

        # Handles management requests such as `/ping` or `/metrics`
        #
        # @api private
        class ServeEndpoints
          JSON_TEXT = { 'Content-Type' => 'application/json' }.freeze
          PLAIN_TEXT = { 'Content-Type' => 'text/plain' }.freeze
          METRICS_TEXT = { 'Content-Type' => Prometheus::Client::Formats::Text::CONTENT_TYPE }.freeze

          PONG = [200, PLAIN_TEXT, ['pong']].freeze
          NOT_FOUND = [404, PLAIN_TEXT, ['not found']].freeze

          # @param registry [Prometheus::Client::Registry]
          def initialize(registry)
            @registry = registry
          end

          # @param env [Hash<String, Any>]
          # @return [(Integer, Hash<String, String>, Array<String>)]
          def call(env) # rubocop:disable Metrics/MethodLength
            return NOT_FOUND if env[::Rack::REQUEST_METHOD] != ::Rack::GET

            case env[::Rack::PATH_INFO]
            when '/ping'
              PONG
            when '/metrics'
              metrics
            when '/gc-stats'
              to_json(GC.stat)
            when '/threads'
              to_json(threads_list)
            else
              NOT_FOUND
            end
          end

          private

          # @return [(Integer, Hash<String, String>, Array<String>)]
          def metrics
            @registry.update_custom_collectors if @registry.respond_to?(:update_custom_collectors)

            text = Prometheus::Client::Formats::Text.marshal(@registry)
            [200, METRICS_TEXT, [text]]
          end

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
            body = ::Puma::JSONSerialization.generate(value)
            [200, JSON_TEXT, [body]]
          end
        end
      end
    end
  end
end

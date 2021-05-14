# frozen_string_literal: true

module BM
  module Instrumentations
    module Puma
      # A collection of Prometheus metrics for Puma server
      #
      # @attr [Prometheus::Client::Gauge] thread_pool_max_size
      # @attr [Prometheus::Client::Gauge] thread_pool_size
      # @attr [Prometheus::Client::Gauge] thread_pool_active_size
      # @attr [Prometheus::Client::Gauge] thread_pool_queue_size
      # @attr [Prometheus::Client::Gauge] socket_backlog_size
      # @attr [Prometheus::Client::Gauge] socket_backlog_max_size
      #
      # @api private
      class MetricsCollection
        include Instrumentations::RegisterMetric

        attr_reader :thread_pool_max_size, :thread_pool_size, :thread_pool_active_size, :thread_pool_queue_size, \
                    :socket_backlog_size, :socket_backlog_max_size

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_server_version(registry)
          build_thread_pool_max_size(registry)
          build_thread_pool_size(registry)
          build_thread_pool_active_size(registry)
          build_thread_pool_queue_size(registry)
          build_socket_backlog_size(registry)
          build_socket_backlog_max_size(registry)
        end

        # Updates gauges from Puma stats
        #
        # @param stats [Hash<Symbol, Integer>]
        # @option stats [Integer] :max_threads
        # @option stats [Integer] :running
        # @option stats [Integer] :pool_capacity
        # @option stats [Integer] :backlog
        def update_stats(stats)
          thread_pool_max_size.set(stats[:max_threads])
          thread_pool_size.set(stats[:running])
          thread_pool_active_size.set(active_workers(stats))
          thread_pool_queue_size.set(stats[:backlog])
        end

        # Updates gauges of backlog values
        #
        # @param listener [Integer]
        # @param backlog [Hash<Symbol, Integer>]
        # @option backlog [Integer] :backlog_size
        # @option backlog [Integer] :backlog_max_size
        def update_backlog(listener:, backlog:)
          labels = { listener: listener }
          socket_backlog_size.set(backlog[:backlog_size], labels: labels)
          socket_backlog_max_size.set(backlog[:backlog_max_size], labels: labels)
        end

        # Sets the Puma server version
        #
        # @param version [String]
        def server_version(version)
          @server_version.set(1, labels: { version: version })
        end

        private

        # @param stats [Hash<Symbol, Integer>]
        # @return [Integer]
        def active_workers(stats)
          # pool_capacity = waiting + (max_threads - running)
          waiting = stats[:pool_capacity] - (stats[:max_threads] - stats[:running])
          stats[:running] - waiting
        end

        def build_server_version(registry)
          @server_version = register_metric(registry, :puma_server_version) do |name|
            registry.gauge(
              name,
              docstring: 'The version number of the running Puma server',
              labels: %i[version]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_thread_pool_max_size(registry)
          @thread_pool_max_size = register_metric(registry, :puma_thread_pool_max_size) do |name|
            registry.gauge(
              name,
              docstring: 'The preconfigured maximum number of worker threads in the Puma server'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_thread_pool_size(registry)
          @thread_pool_size = register_metric(registry, :puma_thread_pool_size) do |name|
            registry.gauge(
              name,
              docstring: 'The number of spawned worker threads in the Puma server'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_thread_pool_active_size(registry)
          @thread_pool_active_size = register_metric(registry, :puma_thread_pool_active_size) do |name|
            registry.gauge(
              name,
              docstring: 'The number of worker threads that actively executing requests in the Puma server'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_thread_pool_queue_size(registry)
          @thread_pool_queue_size = register_metric(registry, :puma_thread_pool_queue_size) do |name|
            registry.gauge(
              name,
              docstring: 'The number of queued requests that waiting execution in the Puma server'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_socket_backlog_size(registry)
          @socket_backlog_size = register_metric(registry, :puma_server_socket_backlog_size) do |name|
            registry.gauge(
              name,
              docstring: 'The current size of the pending connection queue of the Puma listener',
              labels: %i[listener]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_socket_backlog_max_size(registry)
          @socket_backlog_max_size = register_metric(registry, :puma_server_socket_backlog_max_size) do |name|
            registry.gauge(
              name,
              docstring: 'The preconfigured maximum size of the pending connections queue of the Puma listener',
              labels: %i[listener]
            )
          end
        end
      end
    end
  end
end

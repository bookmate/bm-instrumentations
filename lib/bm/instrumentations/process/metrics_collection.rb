# frozen_string_literal: true

module BM
  module Instrumentations
    module Process
      # A collection of Prometheus metrics for Ruby VM & GC
      #
      # @attr [Prometheus::Client::Gauge] process_rss_memory_bytes_count
      # @attr [Prometheus::Client::Gauge] process_open_fds_count
      class MetricsCollection
        include RegisterMetric

        attr_reader :process_rss_memory_bytes_count, :process_open_fds_count

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_process_rss_memory_bytes_count(registry)
          build_process_open_fds_count(registry)
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_process_rss_memory_bytes_count(registry)
          @process_rss_memory_bytes_count = register_metric(registry, :process_rss_memory_bytes_count) do |name|
            registry.gauge(
              name,
              docstring: 'The number of bytes is allocated to this process'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_process_open_fds_count(registry)
          @process_open_fds_count = register_metric(registry, :process_open_fds_count) do |name|
            registry.gauge(
              name,
              docstring: 'The total number of open file descriptor of this process'
            )
          end
        end
      end
    end
  end
end

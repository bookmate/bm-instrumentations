# frozen_string_literal: true

module BM
  module Instrumentations
    module Sequel
      # A collection of Prometheus metrics for Sequel database queries
      #
      # @attr [Prometheus::Client::Counter] queries_total
      # @attr [Prometheus::Client::Histogram] query_duration_seconds
      #
      # @api private
      class MetricsCollection
        include Instrumentations::RegisterMetric

        attr_reader :queries_total, :query_duration_seconds

        # A label value when a query or a database are nil
        NONE = 'none'

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_queries_total(registry)
          build_query_duration_seconds(registry)
        end

        # Record metrics for a database query
        #
        # @param db [String, nil]
        # @param query [String, nil]
        # @param stopwatch [Instrumentations::Stopwatch] is a started timer
        # @param status ['success', 'failure']
        def record_query(db:, query:, stopwatch:, status: 'success')
          labels = {
            database: db || NONE,
            query: query || NONE,
            status: status
          }

          queries_total.increment(labels: labels)
          query_duration_seconds.observe(stopwatch.to_f, labels: labels)
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_query_duration_seconds(registry)
          @query_duration_seconds = register_metric(registry, :sequel_query_duration_seconds) do |name|
            registry.histogram(
              name,
              docstring:
                'The duration in seconds that a Sequel query spent',
              labels: %i[database query status]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_queries_total(registry)
          @queries_total = register_metric(registry, :sequel_queries_total) do |name|
            registry.counter(
              name,
              docstring:
                'How many Sequel queries processed, partitioned by status',
              labels: %i[database query status]
            )
          end
        end
      end
    end
  end
end

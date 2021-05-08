# frozen_string_literal: true

module BM
  module Instrumentations
    module Sequel
      # A collection of Prometheus metrics for Sequel database queries
      #
      # @attr [Prometheus::Client::Counter] queries_total
      # @attr [Prometheus::Client::Histogram] queries_duration_seconds
      class MetricsCollection
        attr_reader :queries_total, :queries_duration_seconds

        # A label value when a query or a database are nil
        UNKNOWN = '-'

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_queries_total(registry)
          build_queries_duration_seconds(registry)
        end

        # Record metrics for a database query
        #
        # @param db [String, nil]
        # @param query [String, nil]
        # @param stopwatch [Instrumentations::Stopwatch] is a started timer
        # @param status ['success', 'fail']
        def record_query(db:, query:, stopwatch:, status: 'success')
          db_name = db || UNKNOWN
          query_name = query || UNKNOWN
          queries_total.increment(labels: { database: db_name, query: query_name, status: status })
          queries_duration_seconds.observe(stopwatch.to_f, labels: { database: db_name, query: query_name })
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_queries_duration_seconds(registry)
          registered = registry.get(:sequel_queries_duration_seconds)
          return @queries_duration_seconds = registered if registered

          @queries_duration_seconds = registry.histogram(
            :sequel_queries_duration_seconds,
            docstring:
              'The duration in seconds that a Sequel query spent',
            labels: %i[database query]
          )
        end

        # @param registry [Prometheus::Client::Registry]
        def build_queries_total(registry)
          registered = registry.get(:sequel_queries_total)
          return @queries_total = registered if registered

          @queries_total = registry.counter(
            :sequel_queries_total,
            docstring:
              'How many Sequel queries processed, partitioned by status',
            labels: %i[database query status]
          )
        end
      end
    end
  end
end

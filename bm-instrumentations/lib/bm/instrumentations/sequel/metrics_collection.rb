# frozen_string_literal: true

require_relative '../internal/if_registered'

module BM
  module Instrumentations
    module Sequel
      # A collection of Prometheus metrics for Sequel database queries
      #
      # @attr [Prometheus::Client::Counter] queries_total
      # @attr [Prometheus::Client::Histogram] queries_duration_seconds
      #
      # @api private
      class MetricsCollection
        include Instrumentations::IfRegistered

        attr_reader :queries_total, :queries_duration_seconds

        # A label value when a query or a database are nil
        NONE = 'none'

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
        # @param status ['success', 'failure']
        def record_query(db:, query:, stopwatch:, status: 'success')
          labels = {
            database: db || NONE,
            query: query || NONE,
            status: status
          }

          queries_total.increment(labels: labels)
          queries_duration_seconds.observe(stopwatch.to_f, labels: labels)
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_queries_duration_seconds(registry)
          if_registered(registry, :sequel_queries_duration_seconds) do |histogram|
            return @queries_duration_seconds = histogram
          end

          @queries_duration_seconds = registry.histogram(
            :sequel_queries_duration_seconds,
            docstring:
              'The duration in seconds that a Sequel query spent',
            labels: %i[database query status]
          )
        end

        # @param registry [Prometheus::Client::Registry]
        def build_queries_total(registry)
          if_registered(registry, :sequel_queries_total) do |counter|
            return @queries_total = counter
          end

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

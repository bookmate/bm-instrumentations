# frozen_string_literal: true

require 'bm/instrumentations'
require 'bm/instrumentations/sequel/metrics_collection'

# :nodoc:
module Sequel
  module Extensions
    # Is a Sequel extension that instrument a database queries and write metrics into Prometheus
    #
    # @example Apply plugin
    #   db = Sequel.connect(...)
    #   db.extension(:prometheus_instrumentation)
    #
    # @example Apply plugin with non default registry
    #   db = Sequel.connect(...)
    #   db.extension(:prometheus_instrumentation)
    #   db.prometheus_registry = registry
    #
    # @attr [MetricsCollection] metrics_collection
    module PrometheusInstrumentation
      attr_reader :metrics_collection

      # Initialize a metrics collection which uses a default prometheus registry
      #
      # @param db [Sequel::Database]
      def self.extended(db)
        db.instance_exec do
          @metrics_collection = BM::Instrumentations::Sequel::MetricsCollection.new(
            Prometheus::Client.registry
          )
        end
      end

      # Override default Prometheus registry
      #
      # @param registry [Prometheus::Client::Registry, nil]
      def prometheus_registry=(registry)
        @metrics_collection = BM::Instrumentations::Sequel::MetricsCollection.new(
          registry || Prometheus::Client.registry
        )
      end

      # :nodoc:
      def log_connection_yield(sql, conn, args = nil) # rubocop:disable Metrics/MethodLength
        stopwatch = BM::Instrumentations::Stopwatch.started
        query = prometheus_query_name_of(sql)
        db = conn.query_options[:database]
        begin
          super(sql, conn, args).tap do |_|
            metrics_collection.record_query(db: db, query: query, stopwatch: stopwatch)
          end
        rescue StandardError
          metrics_collection.record_query(db: db, query: query, stopwatch: stopwatch, status: 'failure')
          raise
        end
      end

      private

      # Returns a query name for given SQL statement
      #
      # @param sql [String, nil]
      # @return [String, nil]
      def prometheus_query_name_of(sql)
        return unless sql

        first_space = sql.index(' ')
        return unless first_space

        sql[0...first_space].downcase
      end
    end
  end

  ::Sequel::Database.register_extension(:prometheus_instrumentation, Extensions::PrometheusInstrumentation)
end

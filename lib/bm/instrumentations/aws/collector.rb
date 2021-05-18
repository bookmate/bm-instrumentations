# frozen_string_literal: true

require 'prometheus/client'

require_relative 'metrics_collection'

module BM
  module Instrumentations
    # Aws client plugin
    module Aws
      # AWS client plugin that instrument API calls and write metrics into Prometheus
      #
      # @example Apply a plugin
      #   Aws::S3::Client.add_plugin(BM::Instrumentations::Aws.plugin)
      #
      # @example Apply a plugin and override the default registry
      #   Aws::S3::Client.add_plugin(BM::Instrumentations::Aws.plugin(registry))
      #
      # @param registry [Prometheus::Client::Registry, nil] overrides a default registry
      # @return [Collector]
      def self.plugin(registry)
        metrics_collection = MetricsCollection.new(registry || Prometheus::Client.registry)
        Collector.new(metrics_collection)
      end

      # An implementation of {Aws::ClientSideMonitoring::Publisher} that publish metrics into
      # Prometheus registry.
      #
      # @attr [MetricsCollection] metrics_collection
      #
      # @see Aws::ClientSideMonitoring::Publisher
      # @api private
      class Collector
        attr_reader :metrics_collection
        attr_accessor :agent_port, :agent_host # for {Aws::ClientSideMonitoring::Publisher} compatibility

        # @param metrics_collection [MetricsCollection]
        def initialize(metrics_collection)
          @metrics_collection = metrics_collection
        end

        # AWS plugin hook, configures a client side monitoring
        #
        # @param _client [Seahorse::Client::Base]
        # @param options [Hash<Symbol, Any>]
        def before_initialize(_client, options)
          options[:client_side_monitoring] = true
          options[:client_side_monitoring_publisher] = self
        end

        # @param request_metrics [Aws::ClientSideMonitoring::RequestMetrics]
        def publish(request_metrics)
          metrics_collection.record_api_call(request_metrics.api_call)
        end
      end
    end
  end
end

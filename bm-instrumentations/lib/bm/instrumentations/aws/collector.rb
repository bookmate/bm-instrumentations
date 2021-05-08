# frozen_string_literal: true

require 'prometheus/client'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    module Aws
      # Is an AWS client plugin that instrument API calls and write metrics into Prometheus
      #
      # @example Apply a plugin
      #   Aws::S3::Client.add_plugin(BM::Instrumentations::Aws::Collector)
      #
      # @example Apply a plugin and override the default registry
      #   Aws::S3::Client.add_plugin(BM::Instrumentations::Aws::Collector[registry])
      #
      # @attr [MetricsCollection] metrics_collection
      # @see [Aws::ClientSideMonitoring::Publisher]
      class Collector
        attr_reader :metrics_collection
        attr_accessor :agent_port, :agent_host # for Aws::ClientSideMonitoring::Publisher compatibility

        # @param registry [Prometheus::Client::Registry, nil] overrides a default registry
        def initialize(registry = nil)
          @metrics_collection = MetricsCollection.new(registry || Prometheus::Client.registry)
        end

        # @param registry [Prometheus::Client::Registry, nil] overrides a default registry
        def self.[](registry)
          new(registry)
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

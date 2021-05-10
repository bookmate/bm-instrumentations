# frozen_string_literal: true

require 'prometheus/middleware/exporter'
require 'bm/instrumentations/rack/collector'

class Roda
  # :nodoc:
  module RodaPlugins
    # The `prometheus_instrumentation` plugin adds the Prometheus exporter and the collector to the application.
    #
    # This is a meta plugins which does nothing except adding (and optionally configuring) two middlewares:
    # * [BM::Instrumentations::Rack::Collector]
    # * [Prometheus::Middleware::Exporter]
    #
    # @example Apply plugin
    #   class API < Roda
    #     plugin(:prometheus_instrumentation)
    #   end
    #
    # @example Apply plugin which non default configuration
    #   class API < Roda
    #     plugin(:prometheus_instrumentation, exclude_path: %w[/metrics /health /ping])
    #   end
    module PrometheusInstrumentation
      # @param app [Any]
      # @param registry [Prometheus::Client::Registry, nil] override the default registry
      # @param exclude_path [String, Array<String>, nil] override the default (/metrics) exclude path
      def self.configure(app, registry: nil, exclude_path: %w[/metrics])
        app.use ::BM::Instrumentations::Rack::Collector, registry: registry, exclude_path: exclude_path
        app.use ::Prometheus::Middleware::Exporter, registry: registry
      end
    end

    register_plugin(:prometheus_instrumentation, PrometheusInstrumentation)
  end
end

# frozen_string_literal: true

require 'bm/instrumentations'

class Roda
  # :nodoc:
  module RodaPlugins
    # The `prometheus_instrumentation` plugin just add {Rack::Collector} to the current Roda application.
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
      def self.configure(app, registry: nil, exclude_path: nil)
        app.use ::BM::Instrumentations::Rack, registry: registry, exclude_path: exclude_path
      end
    end

    register_plugin(:prometheus_instrumentation, PrometheusInstrumentation)
  end
end

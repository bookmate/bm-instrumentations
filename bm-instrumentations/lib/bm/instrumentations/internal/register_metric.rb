# frozen_string_literal: true

module BM
  module Instrumentations
    # Checks if a metric already exist in registry and return of else register
    # a new metric using given block
    #
    # @api private
    module RegisterMetric
      # @param registry [Prometheus::Client::Registry]
      # @param name [Symbol]
      # @yieldparam [Symbol] a metric name
      # @yieldreturn [Prometheus::Client::Metric]
      # @return [Prometheus::Client::Metric]
      def register_metric(registry, name)
        return registry.get(name) if registry.exist?(name)

        yield(name)
      end
    end
  end
end

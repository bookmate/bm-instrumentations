# frozen_string_literal: true

module BM
  module Instrumentations
    # Extends the Prometheus registry to support custom metric collectors
    #
    # @see https://github.com/prometheus/client_ruby/issues/90
    module PrometheusRegistryCustomCollectors
      # Registers a custom collector that poll and update metrics periodically
      #
      # @param collector [Proc]
      def add_custom_collector(&collector)
        @mutex.synchronize do
          @custom_collectors ||= []
          @custom_collectors << collector
        end
      end

      # Invokes all registered custom collectors to update metrics
      #
      # @return [void]
      def update_custom_collectors
        return unless @custom_collectors

        @custom_collectors.each(&:call)
      end
    end
  end
end

Prometheus::Client::Registry.include(BM::Instrumentations::PrometheusRegistryCustomCollectors)

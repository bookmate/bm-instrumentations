# frozen_string_literal: true

module BM
  module Instrumentations
    # Extends the Prometheus registry to support custom metric collectors
    #
    # @see https://github.com/prometheus/client_ruby/issues/90
    module PrometheusRegistryCustomCollectors
      # Initialize custom_collectors array
      def initialize(*args, **kwargs)
        super(*args, **kwargs)
        @custom_collectors = []
      end

      # Registers an updater that poll and update metrics periodically
      #
      # @param collector [Proc]
      def add_custom_collector(&collector)
        @mutex.synchronize do
          @custom_collectors << collector
        end
      end

      # Invokes all registered custom collectors to update metrics
      #
      # @return [void]
      def custom_collectors!
        @custom_collectors.each(&:call)
      end
    end
  end
end

Prometheus::Client::Registry.prepend(BM::Instrumentations::PrometheusRegistryCustomCollectors)

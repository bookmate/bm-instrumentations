# frozen_string_literal: true

require 'prometheus/client'

require_relative 'timings/metrics_collection'

module BM
  module Instrumentations
    # Observes ruby's methods and writes a total number of method's calls into counter
    # and method's timings into histogram.
    #
    # When included it creates two metrics:
    # * `[metric_prefix]_calls_total` - is a counter
    # * `[metric_prefix]_call_duration_seconds` - is a histogram
    #
    # Each metrics labeled with:
    # * `class` - a class name where the module included
    # * `method` - a ruby's method which observed
    # * `status` - one of `success` or `failure`
    #
    # @example Measure a ruby's method
    #   class QueryUsers
    #     include BM::Instrumentations::Timings[:users]
    #
    #     def query(params)
    #       ...
    #     end
    #     timings :query
    #   end
    class Timings < Module
      # Stores a module configuration into variables for later usage
      #
      # @param metrics_prefix [Symbol] each metric name will have this prefix
      # @param registry [Prometheus::Client::Registry, nil] overrides the default registry
      def initialize(metrics_prefix, registry)
        super()
        @metrics_prefix = metrics_prefix
        @registry = registry || Prometheus::Client.registry
      end
      private_class_method :new

      # The public constructor
      #
      # @param metrics_prefix [Symbol]
      # @param registry [Prometheus::Client::Registry, nil] overrides the default registry
      def self.[](metrics_prefix, registry: nil)
        new(metrics_prefix, registry)
      end

      # Creates and configure a [MetricsCollection]
      #
      # @param base [Class]
      def included(base)
        metrics_collection = MetricsCollection.new(
          registry: @registry,
          metrics_prefix: @metrics_prefix,
          class_name: base.name
        )

        base.define_singleton_method(:timings_instrumentation) { metrics_collection }
        base.extend ClassMethods
      end

      # Exports the :timings function's decorator
      module ClassMethods
        # @param method_name [Symbol]
        def timings(method_name)
          prepend(Module.new do
            define_method(method_name) do |*args, **kwargs, &block|
              self.class.timings_instrumentation.observe(method_name) { super(*args, **kwargs, &block) }
            end
          end)
        end
      end
    end
  end
end

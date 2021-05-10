# frozen_string_literal: true

require_relative '../internal/stopwatch'
require_relative '../internal/if_registered'

module BM
  module Instrumentations
    class Timings < Module
      # Observes ruby's methods and writes a total number of method's calls into counter
      # and method's timings into histogram.
      #
      # Each metrics labeled with:
      # * `class` - a class name where the module included
      # * `method` - a ruby's method which observed
      # * `status` - one of `success` or `failure`
      #
      # @attr [Prometheus::Client::Counter] calls_total
      # @attr [Prometheus::Client::Histogram] call_duration_seconds
      # @attr [String] class_name
      #
      # @api private
      class MetricsCollection
        include Instrumentations::IfRegistered

        attr_reader :class_name, :calls_total, :call_duration_seconds

        # @param registry [Prometheus::Client::Registry]
        # @param metrics_prefix [String, Symbol]
        # @param class_name [String]
        def initialize(registry:, metrics_prefix:, class_name:)
          @class_name = class_name
          build_calls_total(registry, metrics_prefix)
          build_call_duration_seconds(registry, metrics_prefix)
        end

        # Invokes and then record metrics for an invoked ruby's method
        #
        # @example
        #   metrics_collection.observe { long_running_job }
        #
        # @param method [Symbol]
        def observe(method)
          stopwatch = Stopwatch.started
          begin
            yield.tap { record_call(method: method, stopwatch: stopwatch) }
          rescue StandardError
            record_call(method: method, stopwatch: stopwatch, status: 'failure')
            raise
          end
        end

        private

        # @param method [Symbol]
        # @param stopwatch [Stopwatch]
        # @param status ['success', 'failure']
        def record_call(method:, stopwatch:, status: 'success')
          labels = {
            class: class_name,
            method: method,
            status: status
          }
          calls_total.increment(labels: labels)
          call_duration_seconds.observe(stopwatch.to_f, labels: labels)
        end

        # @param registry [Prometheus::Client::Registry]
        # @param metrics_prefix [String, Symbol]
        def build_calls_total(registry, metrics_prefix)
          name = "#{metrics_prefix}_calls_total".to_sym
          if_registered(registry, name) do |counter|
            return @calls_total = counter
          end

          @calls_total = registry.counter(
            name,
            docstring: "The total number of of successful or failed calls by ruby's method",
            labels: %i[class method status]
          )
        end

        # @param registry [Prometheus::Client::Registry]
        # @param metrics_prefix [String, Symbol]
        def build_call_duration_seconds(registry, metrics_prefix)
          name = "#{metrics_prefix}_call_duration_seconds".to_sym
          if_registered(registry, name) do |counter|
            return @call_duration_seconds = counter
          end

          @call_duration_seconds = registry.histogram(
            name,
            docstring: "The time in seconds which spent at ruby's method calls",
            labels: %i[class method status]
          )
        end
      end
    end
  end
end

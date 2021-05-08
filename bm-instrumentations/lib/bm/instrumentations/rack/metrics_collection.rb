# frozen_string_literal: true

module BM
  module Instrumentations
    module Rack
      # A collection of Prometheus metrics for HTTP server requests and responses
      #
      # @attr [Prometheus::Client::Counter] requests_total
      # @attr [Prometheus::Client::Histogram] requests_duration_seconds
      # @attr [Prometheus::Client::Counter] exceptions_total
      #
      # @api private
      class MetricsCollection
        attr_reader :requests_total, :requests_duration_seconds, :exceptions_total

        # A label value when an endpoint's path is unknown
        NONE = 'none'

        # A HTTP status code for failed requests
        INTERNAL_SERVER_ERROR = 500

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_requests_total(registry)
          build_requests_duration_seconds(registry)
          build_exceptions_total(registry)
        end

        # Record metrics for a handled request
        #
        # @param status [Integer] is a HTTP status code from response
        # @param method [String] is a HTTP method from request
        # @param path [String, nil] is a HTTP path name of handled request, may be nil
        # @param stopwatch [Instrumentations::Stopwatch] is a started timer
        def record_request(status:, method:, path:, stopwatch:)
          labels = {
            status: status,
            method: method,
            path: path || NONE
          }

          requests_total.increment(labels: labels)
          requests_duration_seconds.observe(stopwatch.to_f, labels: labels)
        end

        # Record metrics for a failed request (with an exception)
        #
        # @param method [String] is a HTTP method from request
        # @param path [String, nil] is a HTTP path name of handled request, may be nil
        # @param stopwatch [Instrumentations::Stopwatch] is a started timer
        # @param exception [StandardError] is an uncaught exception
        def record_exception(method:, path:, stopwatch:, exception:)
          record_request(status: INTERNAL_SERVER_ERROR, method: method, path: path, stopwatch: stopwatch)

          labels = {
            method: method,
            path: path || NONE,
            exception: exception.class.name
          }
          exceptions_total.increment(labels: labels)
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_exceptions_total(registry)
          @exceptions_total = registry.counter(
            :http_server_exceptions_total,
            docstring:
              'The total number of uncaught exceptions raised by the Rack application',
            labels: %i[method path exception]
          )
        end

        # @param registry [Prometheus::Client::Registry]
        def build_requests_duration_seconds(registry)
          @requests_duration_seconds = registry.histogram(
            :http_server_requests_duration_seconds,
            docstring:
              'The HTTP response times in seconds from the Rack application',
            labels: %i[method path status]
          )
        end

        # @param registry [Prometheus::Client::Registry]
        def build_requests_total(registry)
          @requests_total = registry.counter(
            :http_server_requests_total,
            docstring:
              'The total number of HTTP requests handled by the Rack application',
            labels: %i[method path status]
          )
        end
      end
    end
  end
end

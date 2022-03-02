# frozen_string_literal: true

require 'rack'

require_relative 'endpoint'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    # Rack middleware that collect metrics for HTTP requests and responses.
    #
    # @example Use middleware
    #   use BM::Instrumentations::Rack, exclude_path: %w[/metrics /health /ping]
    #
    # @example Use middleware with non default registry
    #   use BM::Instrumentations::Rack, registry: registry
    #
    # @attr [Proc] app
    # @attr [MetricsCollection] metrics_collection
    # @attr [Array<String>] exclude_path
    class Rack
      attr_reader :app, :exclude_path, :metrics_collection

      # @param app [Proc]
      # @param options [Hash]
      #   * :exclude_path [String, Array<String>, nil] a list of ignored path names, for that paths the metrics won't
      #     be record
      #   * :registry [Prometheus::Client::Registry, nil] overrides the default Prometheus registry
      def initialize(app, options = {})
        @app = app
        @exclude_path = Array(options[:exclude_path]).freeze
        @metrics_collection = MetricsCollection.new(options[:registry] || Prometheus::Client.registry)
      end

      # @param env [Hash]
      # @return [Array]
      def call(env)
        stopwatch = Stopwatch.started
        return app.call(env) unless record?(env)

        record(env, stopwatch)
      end

      private

      # Record metrics for given request
      #
      # @param env [Hash]
      # @param stopwatch [Stopwatch]
      # @return [Array]
      def record(env, stopwatch)
        app.call(env).tap { record_success(env, _1, stopwatch) }
      rescue StandardError => e
        record_exception(env, e, stopwatch)
        raise
      end

      # @param env [Hash]
      # @param response [(Integer, Hash, Array)]
      # @param stopwatch [Stopwatch]
      def record_success(env, response, stopwatch)
        metrics_collection.record_request(
          status_code: status_code(response),
          method: env[::Rack::REQUEST_METHOD],
          path: env[ENDPOINT],
          stopwatch: stopwatch
        )
      end

      # @param env [Hash]
      # @param exception [Exception]
      # @param stopwatch [Stopwatch]
      def record_exception(env, exception, stopwatch)
        metrics_collection.record_exception(
          method: env[::Rack::REQUEST_METHOD],
          path: env[ENDPOINT],
          stopwatch: stopwatch,
          exception: exception
        )
      end

      # @param response [(Integer, Hash, Array)]
      # @return [Integer]
      def status_code(response)
        code = response[1][STATUS_CODE_INTERNAL].to_i
        code.positive? ? code : response.first
      end

      # Is metrics will be recorded for this request
      #
      # @param env [Hash]
      # @return [Boolean]
      def record?(env)
        !exclude_path.include?(env[::Rack::PATH_INFO])
      end
    end
  end
end

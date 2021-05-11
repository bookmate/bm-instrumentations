# frozen_string_literal: true

module BM
  module Instrumentations
    module Aws
      # A collection of Prometheus metrics for Aws SDK clients
      #
      # @attr [Prometheus::Client::Counter] requests_total
      # @attr [Prometheus::Client::Counter] exceptions_total
      # @attr [Prometheus::Client::Counter] retries_total
      # @attr [Prometheus::Client::Histogram] request_duration_seconds
      #
      # @api private
      class MetricsCollection
        include Instrumentations::RegisterMetric

        attr_reader :requests_total, :exceptions_total, :retries_total, :request_duration_seconds

        # The number of milliseconds in the one second
        MS_IN_SECOND = 1_000.0

        # Is a HTTP status code when a request failed with an exception
        INTERNAL_SERVER_ERROR = 500

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_requests_total(registry)
          build_exceptions_total(registry)
          build_retries_total(registry)
          build_request_duration_seconds(registry)
        end

        # Records a metrics for given API Call
        #
        # @param api_call [Aws::ClientSideMonitoring::RequestMetrics::ApiCall]
        def record_api_call(api_call)
          duration = api_call.latency / MS_IN_SECOND
          labels = default_labels_for(api_call)

          requests_total.increment(labels: labels)
          request_duration_seconds.observe(duration, labels: labels)
          increment_exceptions_total(api_call) if api_call.final_aws_exception
          increment_retries_total(api_call) if api_call.attempt_count > 1
        end

        private

        # @param api_call [Aws::ClientSideMonitoring::RequestMetrics::ApiCall]
        def increment_retries_total(api_call)
          labels = {
            service: api_call.service,
            api: api_call.api
          }
          retries_total.increment(by: (api_call.attempt_count - 1), labels: labels)
        end

        # @param api_call [Aws::ClientSideMonitoring::RequestMetrics::ApiCall]
        def increment_exceptions_total(api_call)
          labels = {
            service: api_call.service,
            api: api_call.api,
            exception: api_call.final_aws_exception.to_s
          }
          exceptions_total.increment(labels: labels)
        end

        # @param api_call [Aws::ClientSideMonitoring::RequestMetrics::ApiCall]
        def default_labels_for(api_call)
          status = api_call.final_aws_exception ? INTERNAL_SERVER_ERROR : api_call.final_http_status_code
          {
            status: status,
            service: api_call.service,
            api: api_call.api
          }
        end

        # @param registry [Prometheus::Client::Registry]
        def build_request_duration_seconds(registry)
          @request_duration_seconds = register_metric(registry, :aws_sdk_client_request_duration_seconds) do |name|
            registry.histogram(
              name,
              docstring:
                'The total time in seconds for the AWS Client to make a call to AWS services',
              labels: %i[service api status]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_requests_total(registry)
          @requests_total = register_metric(registry, :aws_sdk_client_requests_total) do |name|
            registry.counter(
              name,
              docstring:
                'The total number of successful or failed API calls from AWS client to AWS services',
              labels: %i[service api status]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_retries_total(registry)
          @retries_total = register_metric(registry, :aws_sdk_client_retries_total) do |name|
            registry.counter(
              name,
              docstring:
                'The total number retries of failed API calls from AWS client to AWS services',
              labels: %i[service api]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_exceptions_total(registry)
          @exceptions_total = register_metric(registry, :aws_sdk_client_exceptions_total) do |name|
            registry.counter(
              name,
              docstring:
                'The total number of AWS API calls that fail',
              labels: %i[service api exception]
            )
          end
        end
      end
    end
  end
end

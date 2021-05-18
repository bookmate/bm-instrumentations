# frozen_string_literal: true

require 'aws-sdk-s3'
require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Aws::Collector do
  subject(:collector) { BM::Instrumentations::Aws.plugin(registry) }

  let(:access_key_id) { ENV.fetch('AWS_ACCESS_KEY_ID', 'AccessKey') }
  let(:secret_key) { ENV.fetch('AWS_SECRET_KEY', 'SecretKey') }
  let(:s3_host) { ENV.fetch('S3_HOST', 'localhost:9000') }
  let(:s3_client) do
    Aws::S3::Client.add_plugin(collector)
    Aws::S3::Client.new(
      credentials: Aws::Credentials.new(access_key_id, secret_key),
      endpoint: "http://#{s3_host}",
      force_path_style: true,
      region: 'us-east-1'
    )
  end

  it 'registers metrics in registry' do
    collector

    expect(registry.get(:aws_sdk_client_requests_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:aws_sdk_client_exceptions_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:aws_sdk_client_retries_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:aws_sdk_client_request_duration_seconds)).to be_kind_of(Prometheus::Client::Histogram)
  end

  context 'when registered twice' do
    subject(:second_collector) { BM::Instrumentations::Aws.plugin(registry) }

    it 'shares same metrics' do
      expect(second_collector.metrics_collection.request_duration_seconds).to \
        eq(collector.metrics_collection.request_duration_seconds)

      expect(second_collector.metrics_collection.requests_total).to \
        eq(collector.metrics_collection.requests_total)

      expect(second_collector.metrics_collection.exceptions_total).to \
        eq(collector.metrics_collection.exceptions_total)

      expect(second_collector.metrics_collection.retries_total).to \
        eq(collector.metrics_collection.retries_total)
    end
  end

  describe 'collect metrics' do
    let(:labels) { { status: 200, service: 'S3', api: 'ListBuckets' } }

    before { s3_client.list_buckets }

    it_behaves_like 'increments a counter', :aws_sdk_client_requests_total
    it_behaves_like 'fills a histogram buckets', :aws_sdk_client_request_duration_seconds
    it_behaves_like 'does not increment a counter', :aws_sdk_client_exceptions_total
    it_behaves_like 'does not increment a counter', :aws_sdk_client_retries_total
  end

  describe 'collect metrics', 'when an exception has raised' do
    let(:labels) { { status: 500, service: 'S3', api: 'ListBuckets' } }
    let(:s3_host) { "127.0.0.1:#{non_listening_port}" }

    before do
      expect { s3_client.list_buckets }.to raise_error(Seahorse::Client::NetworkingError)
    end

    it_behaves_like 'increments a counter', :aws_sdk_client_requests_total
    it_behaves_like 'fills a histogram buckets', :aws_sdk_client_request_duration_seconds
    it_behaves_like(
      'increments a counter',
      :aws_sdk_client_exceptions_total,
      service: 'S3', api: 'ListBuckets', exception: 'Seahorse::Client::NetworkingError'
    )

    it 'increments a :aws_sdk_client_retries_total' do
      expect(counter_value(:aws_sdk_client_retries_total, service: 'S3', api: 'ListBuckets')).to eq(3.0)
    end
  end
end

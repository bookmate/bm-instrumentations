# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Rack::Collector, rack: true do
  subject(:app) do
    described_class.new(callable, exclude_path: exclude_path, registry: registry)
  end

  let(:exclude_path) { '/ignore' }
  let(:status_code) { 200 }
  let(:callable) { ->(env) { [status_code, env, 'app'] } }

  it 'registers metrics in registry' do
    app

    expect(registry.get(:http_server_requests_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:http_server_exceptions_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:http_server_request_duration_seconds)).to be_kind_of(Prometheus::Client::Histogram)
  end

  context 'when registered twice' do
    subject(:second_app) { described_class.new(callable, registry: registry) }

    it 'shares same metrics' do
      expect(second_app.metrics_collection.request_duration_seconds).to \
        eq(app.metrics_collection.request_duration_seconds)

      expect(second_app.metrics_collection.requests_total).to \
        eq(app.metrics_collection.requests_total)

      expect(second_app.metrics_collection.exceptions_total).to \
        eq(app.metrics_collection.exceptions_total)
    end
  end

  describe 'collect metrics' do
    let(:labels) { { status: '2xx', status_code: 200, method: 'GET', path: 'none' } }

    before { get '/' }

    it 'is ok response' do
      expect(last_response).to be_ok
      expect(last_response.body).to eq('app')
    end

    it_behaves_like 'increments a counter', :http_server_requests_total
    it_behaves_like 'fills a histogram buckets', :http_server_request_duration_seconds
    it_behaves_like 'does not increment a counter', :http_server_exceptions_total
  end

  describe 'collect metrics', 'when HTTP status code is not 200' do
    let(:status_code) { 401 }
    let(:labels) { { status: '4xx', status_code: status_code, method: 'GET', path: 'none' } }

    before { get '/' }

    it 'is ok response' do
      expect(last_response.status).to eq(status_code)
      expect(last_response.body).to eq('app')
    end

    it_behaves_like 'increments a counter', :http_server_requests_total
    it_behaves_like 'fills a histogram buckets', :http_server_request_duration_seconds
    it_behaves_like 'does not increment a counter', :http_server_exceptions_total
  end

  describe 'collect metrics', 'with uncaught exception' do
    let(:labels) { { status: '5xx', status_code: 500, method: 'GET', path: 'none' } }
    let(:callable) { ->(_) { raise 'boom' } }

    before { expect { get '/' }.to raise_error('boom') }

    it_behaves_like 'increments a counter', :http_server_requests_total
    it_behaves_like 'fills a histogram buckets', :http_server_request_duration_seconds
    it_behaves_like 'increments a counter', :http_server_exceptions_total, \
                    method: 'GET', path: 'none', exception: 'RuntimeError'
  end

  describe 'collect metrics', 'when an endpoint has a name' do
    let(:labels) { { status: '2xx', status_code: 200, method: 'GET', path: 'endpoint_name' } }
    let(:callable) do
      lambda do |env|
        env[BM::Instrumentations::Rack::ENDPOINT] = 'endpoint_name'
        [status_code, env, 'app']
      end
    end

    before { get '/' }

    it_behaves_like 'increments a counter', :http_server_requests_total
    it_behaves_like 'fills a histogram buckets', :http_server_request_duration_seconds
    it_behaves_like 'does not increment a counter', :http_server_exceptions_total
  end

  describe 'collect metrics', 'when endpoint has a name and an uncaught exception' do
    let(:labels) { { status: '5xx', status_code: 500, method: 'GET', path: 'endpoint_name' } }
    let(:callable) do
      lambda do |env|
        env[BM::Instrumentations::Rack::ENDPOINT] = 'endpoint_name'
        raise 'boom'
      end
    end

    before { expect { get '/' }.to raise_error('boom') }

    it_behaves_like 'increments a counter', :http_server_requests_total
    it_behaves_like 'fills a histogram buckets', :http_server_request_duration_seconds
    it_behaves_like 'increments a counter', :http_server_exceptions_total, \
                    method: 'GET', path: 'endpoint_name', exception: 'RuntimeError'
  end

  describe 'when path is ignored' do
    before { get exclude_path }

    it 'is ok response' do
      expect(last_response).to be_ok
      expect(last_response.body).to eq('app')
    end

    it_behaves_like 'does not increment a counter', :http_server_requests_total
    it_behaves_like 'does not increment a counter', :http_server_exceptions_total
    it_behaves_like 'does not fill a histogram buckets', :http_server_request_duration_seconds
  end
end

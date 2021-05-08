# frozen_string_literal: true

require 'bm/instrumentations/rack/collector'

RSpec.describe BM::Instrumentations::Rack::Collector, rack: true do
  subject(:app) do
    described_class.new(callable, exclude_path: exclude_path, registry: registry)
  end

  let(:registry) { Prometheus::Client::Registry.new }
  let(:exclude_path) { '/ignore' }
  let(:code) { 200 }
  let(:callable) do
    lambda do |env|
      sleep 0.2
      [code, env, 'app']
    end
  end

  shared_examples 'increments a :http_server_requests_total' do
    it 'increments a :http_server_requests_total' do
      expect(counter(:http_server_requests_total, labels)).to eq(1.0)
    end
  end

  shared_examples 'fills a :http_server_request_duration_seconds buckets' do
    it 'fills a :http_server_request_duration_seconds buckets' do
      expected = { '0.005' => 0.0, '1' => 1.0 }
      expect(histogram(:http_server_requests_duration_seconds, labels)).to include(expected)
    end
  end

  shared_examples 'does not increment :http_server_exceptions_total' do
    it 'does not increment :http_server_exceptions_total' do
      expect(values(:http_server_exceptions_total)).to be_empty
    end
  end

  shared_examples 'increments :http_server_exceptions_total' do
    it 'increments :http_server_exceptions_total' do
      labels = { exception: 'RuntimeError' }
      expect(counter(:http_server_exceptions_total, labels)).to eq(1.0)
    end
  end

  describe 'collect metrics' do
    let(:labels) { { code: 200, method: 'GET', path: '-' } }

    before { get '/' }

    it 'is ok response' do
      expect(last_response).to be_ok
      expect(last_response.body).to eq('app')
    end

    it_behaves_like 'increments a :http_server_requests_total'
    it_behaves_like 'fills a :http_server_request_duration_seconds buckets'
    it_behaves_like 'does not increment :http_server_exceptions_total'
  end

  describe 'collect metrics', 'when HTTP status code is not 200' do
    let(:code) { 401 }
    let(:labels) { { code: code, method: 'GET', path: '-' } }

    before { get '/' }

    it 'is ok response' do
      expect(last_response.status).to eq(code)
      expect(last_response.body).to eq('app')
    end

    it_behaves_like 'increments a :http_server_requests_total'
    it_behaves_like 'fills a :http_server_request_duration_seconds buckets'
    it_behaves_like 'does not increment :http_server_exceptions_total'
  end

  describe 'collect metrics', 'when an exception has raised' do
    let(:labels) { { code: 500, method: 'GET', path: '-' } }
    let(:callable) do
      lambda do |_|
        sleep 0.2
        raise 'boom'
      end
    end

    before { expect { get '/' }.to raise_error('boom') }

    it_behaves_like 'increments a :http_server_requests_total'
    it_behaves_like 'fills a :http_server_request_duration_seconds buckets'
    it_behaves_like 'increments :http_server_exceptions_total'
  end

  describe 'collect metrics', 'when endpoint name in Rack env' do
    let(:labels) { { code: 200, method: 'GET', path: 'endpoint_name' } }
    let(:callable) do
      lambda do |env|
        sleep 0.2
        env[BM::Instrumentations::Rack::ENDPOINT] = 'endpoint_name'
        [code, env, 'app']
      end
    end

    before { get '/' }

    it_behaves_like 'increments a :http_server_requests_total'
    it_behaves_like 'fills a :http_server_request_duration_seconds buckets'
    it_behaves_like 'does not increment :http_server_exceptions_total'
  end

  describe 'collect metrics', 'when endpoint name in Rack env and an exception' do
    let(:labels) { { code: 500, method: 'GET', path: 'endpoint_name' } }
    let(:callable) do
      lambda do |env|
        sleep 0.2
        env[BM::Instrumentations::Rack::ENDPOINT] = 'endpoint_name'
        raise 'boom'
      end
    end

    before { expect { get '/' }.to raise_error('boom') }

    it_behaves_like 'increments a :http_server_requests_total'
    it_behaves_like 'fills a :http_server_request_duration_seconds buckets'
    it_behaves_like 'increments :http_server_exceptions_total'
  end

  describe 'when path is ignored' do
    before { get exclude_path }

    it 'is ok response' do
      expect(last_response).to be_ok
      expect(last_response.body).to eq('app')
    end

    it 'does not increment :http_server_requests_total' do
      expect(values(:http_server_requests_total)).to be_empty
    end

    it 'does not fill :http_server_request_duration_seconds buckets' do
      expect(values(:http_server_requests_duration_seconds)).to be_empty
    end

    it 'does not increment :http_server_exceptions_total' do
      expect(values(:http_server_exceptions_total)).to be_empty
    end
  end

  def values(name)
    registry.get(name)&.values || {}
  end

  # @return [Float]
  def counter(name, labels = {})
    registry.get(name)&.get(labels: labels) || 0.0
  end

  # @return [Hash<String, Float>]
  def histogram(name, labels = {})
    registry.get(name)&.get(labels: labels) || {}
  end
end

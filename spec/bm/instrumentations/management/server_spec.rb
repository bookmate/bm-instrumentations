# frozen_string_literal: true

require 'net/http'
require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Management::Server, net_http: true do
  subject(:server_run) { described_class.run(host: host, port: 0, registry: registry) }

  let(:host) { '127.0.0.1' }
  let(:registry) { Prometheus::Client::Registry.new }
  let(:uri) { URI("http://#{host}:#{server_run.port}#{endpoint}") }
  let(:response) { Net::HTTP.get_response(uri) }

  before { server_run }

  after { server_run.shutdown }

  shared_examples 'when non GET request' do
    subject(:response) { Net::HTTP.post(uri, '') }

    it 'responds with 404' do
      expect(response).to be_not_found.have_content_type('text/plain')
      expect(response).to have_body('not found')
    end
  end

  describe 'a /ping endpoint' do
    let(:endpoint) { '/ping' }

    it 'responds successfully' do
      expect(response).to be_ok.have_content_type('text/plain')
      expect(response).to have_body('pong')
    end

    it_behaves_like 'when non GET request'
  end

  describe 'a /metrics endpoint' do
    let(:endpoint) { '/metrics' }

    before do
      counter = registry.counter(:tests_total, docstring: 'Testing')
      counter.increment
    end

    it 'responds successfully' do
      expect(response).to be_ok.have_content_type('text/plain; version=0.0.4')
      expect(response).to have_body("# TYPE tests_total counter\n# HELP tests_total Testing\ntests_total 1.0\n")
    end

    it_behaves_like 'when non GET request'
  end

  describe 'a /gc-stats endpoint' do
    let(:endpoint) { '/gc-stats' }

    it 'responds successfully' do
      expect(response).to be_ok.have_content_type('application/json')
      expect(response).to have_body('"heap_allocated_pages":')
    end

    it_behaves_like 'when non GET request'
  end

  describe 'a /threads endpoint' do
    let(:endpoint) { '/threads' }

    it 'responds successfully' do
      expect(response).to be_ok.have_content_type('application/json')
      expect(response).to have_body(__FILE__)
      expect(response).to have_body('"name":"puma threadpool 001"')
      expect(response).to have_body('"name":"puma management-server"')
    end

    it_behaves_like 'when non GET request'
  end

  describe 'with non existing endpoint' do
    let(:endpoint) { '/notfound' }

    it 'responds with 404' do
      expect(response).to be_not_found.have_content_type('text/plain')
      expect(response).to have_body('not found')
    end
  end
end

# frozen_string_literal: true

require 'roda'

RSpec.describe 'Roda::RodaPlugins::PrometheusInstrumentation', rack: true do
  let(:app) do
    cls = Class.new(::Roda)
    cls.plugin(:prometheus_instrumentation, registry: registry)
    cls.route do |r|
      r.root { 'root' }
    end
    cls.app.freeze
  end

  it 'responds to /metrics' do
    get '/metrics'

    expect(last_response).to be_ok
    expect(last_response['Content-Type']).to eq('text/plain; version=0.0.4')
    expect(last_response.body).to include("TYPE http_server_requests_total counter\n")
    expect(last_response.body).to include("TYPE http_server_request_duration_seconds histogram\n")
  end
end

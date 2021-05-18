# frozen_string_literal: true

require 'roda'
require 'prometheus/client'

RSpec.describe 'Roda::RodaPlugins::PrometheusInstrumentation', rack: true do
  let(:app) do
    cls = Class.new(::Roda)
    cls.plugin(:prometheus_instrumentation, registry: registry)
    cls.route do |r|
      r.root { 'root' }
    end
    cls.app.freeze
  end

  it 'collects metrics' do
    expect { get '/' }.to change { requests_total }.by(1)
  end

  # @return [Integer]
  def requests_total
    registry.get(:http_server_requests_total)&.values&.size || 0
  end
end

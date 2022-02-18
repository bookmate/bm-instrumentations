# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Process::Collector do
  before do
    BM::Instrumentations::Process.install(registry)
  end

  context 'when Linux' do
    before do
      skip('Linux only') unless RUBY_PLATFORM.include?('linux')
    end

    it 'registers metrics in registry' do
      expect(registry.get(:process_rss_memory_bytes_count)).to be_kind_of(Prometheus::Client::Gauge)
      expect(registry.get(:process_open_fds_count)).to be_kind_of(Prometheus::Client::Gauge)
    end
  end

  context 'when MacOS' do
    before do
      skip('MacOS only') unless RUBY_PLATFORM.include?('darwin')
    end

    it 'does not register metrics in registry' do
      expect(registry.get(:process_rss_memory_bytes_count)).to be_nil
      expect(registry.get(:process_open_fds_count)).to be_nil
    end
  end

  describe '#call', 'when Linux' do
    subject(:update) { registry.update_custom_collectors }

    before do
      skip('Linux only') unless RUBY_PLATFORM.include?('linux')
      update
    end

    it 'sets a :process_rss_memory_bytes_count' do
      expect(gauge_value(:process_rss_memory_bytes_count)).to be_positive
    end

    it 'sets a :process_open_fds_count' do
      expect(gauge_value(:process_open_fds_count)).to be_positive
    end
  end
end

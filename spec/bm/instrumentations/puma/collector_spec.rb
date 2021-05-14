# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Puma::Collector do
  subject(:collector) { described_class.new(registry: registry, launcher: launcher) }

  let(:launcher) { instance_double('Puma::Launcher') }
  let(:stats) do
    {
      max_threads: 11,
      running: 7,
      backlog: 4,
      pool_capacity: 5
    }
  end
  let(:listener) { TCPServer.new('127.0.0.1', 0) }
  let(:client) { TCPSocket.new('127.0.0.1', listener.addr[1]) }

  before do
    binder = instance_double('Puma::Binder')
    allow(launcher).to receive(:stats).and_return(stats)
    allow(launcher).to receive(:binder).and_return(binder)
    allow(binder).to receive(:ios).and_return([listener])
  end

  after { [client, listener].each(&:close) }

  it 'assigns the Puma server version' do
    collector

    expect(gauge_value(:puma_server_version, version: Puma::Server::VERSION)).to eq(1.0)
  end

  describe '#update', 'with launcher stats' do
    before do
      collector.update
    end

    it 'fetches stats from launcher' do
      expect(launcher).to have_received(:stats)
    end

    it 'updates :puma_thread_pool_max_size gauge' do
      expect(gauge_value(:puma_thread_pool_max_size)).to eq(11.0)
    end

    it 'updates :puma_thread_pool_size gauge' do
      expect(gauge_value(:puma_thread_pool_size)).to eq(7.0)
    end

    it 'updates :puma_thread_pool_active_size gauge' do
      expect(gauge_value(:puma_thread_pool_active_size)).to eq(6.0)
    end

    it 'updates :puma_thread_pool_queue_size gauge' do
      expect(gauge_value(:puma_thread_pool_queue_size)).to eq(4.0)
    end
  end

  describe '#update', 'with socket backlog' do
    let(:labels) { { listener: 0 } }

    before do
      skip('TCP_INFO is Linux only') unless TCPServer.method_defined?(:socket_backlog)

      client
      collector.update
    end

    it 'updates :puma_server_socket_backlog_max_size gauge' do
      expect(gauge_value(:puma_server_socket_backlog_max_size, labels)).to be_positive
    end

    it 'updates :puma_server_socket_backlog_size gauge' do
      expect(gauge_value(:puma_server_socket_backlog_size, labels)).to eq(1.0)
    end

    it 'calls TCP_INFO on listening socket' do
      expect(launcher).to have_received(:binder)
      expect(launcher.binder).to have_received(:ios)
    end
  end
end

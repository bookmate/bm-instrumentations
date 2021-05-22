# frozen_string_literal: true

require 'bm/instrumentations/puma/tcp_info'

RSpec.describe BM::Instrumentations::Puma::TcpInfo do
  subject(:tcp_info) { described_class.new }

  let(:tcp_server) { TCPServer.new('127.0.0.1', 0) }
  let(:backlog_size) { 13 }

  before do
    tcp_server.listen(backlog_size)
    skip('Linux only') unless tcp_info.available?
  end

  after { tcp_server.close }

  it 'is available' do
    expect(tcp_info).to be_available
  end

  it 'returns the max backlog size' do
    expect(tcp_info.of(tcp_server)).to include(backlog_max_size: backlog_size)
  end

  context 'with connected clients' do
    let(:clients) { (1..3).map { TCPSocket.new('127.0.0.1', tcp_server.addr[1]) } }

    after do
      clients.map(&:close)
    end

    it 'return the current backlog size' do
      expect { clients }.to change { tcp_info.of(tcp_server)[:backlog_size] }.from(0).to(3)
    end
  end
end

# frozen_string_literal: true

require 'net/http'
require 'puma'

RSpec.describe 'Puma::Plugin::ManagementServer', integration: true, net_http: true do
  let(:host) { '127.0.0.1' }
  let(:management_port) { 3001 }
  let(:puma_port) { 3000 }
  let(:puma) do
    Puma::Launcher.new(Puma::Configuration.new do |cfg|
      cfg.bind "tcp://#{host}:#{puma_port}"
      cfg.threads 2, 2

      cfg.plugin(:management_server)
      cfg.management_server(host: host, port: management_port)
      cfg.app ->(_) { [200, {}, ['hello']] }
    end)
  end

  before { Thread.new { puma.run } }

  after { puma.stop }

  it 'starts puma and management server and capture metrics' do
    [puma_port, management_port].each { wait_for(_1) }

    hello = Net::HTTP.get_response(URI("http://#{host}:#{puma_port}"))
    expect(hello).to be_ok.have_body('hello')

    pong = Net::HTTP.get_response(URI("http://#{host}:#{management_port}/ping"))
    expect(pong).to be_ok.have_body('pong')

    metrics = Net::HTTP.get_response(URI("http://#{host}:#{management_port}/metrics"))
    inspect_metrics(metrics)

    # no treamer and ripper threads for management
    ths = Thread.list.map(&:name).reject(&:nil?).select { _1.include? 'puma management-server' }.sort
    expect(ths).to eq(['puma management-server', 'puma management-server tp 001'])
  end

  def inspect_metrics(metrics)
    expect(metrics).to be_ok

    body = metrics.body
    expect(body).to include("puma_thread_pool_max_size 2.0\n")
    expect(body).to include("puma_thread_pool_size 2.0\n")
    expect(body).to include("puma_thread_pool_active_size 0.0\n")
    expect(body).to include("puma_thread_pool_queue_size 0.0\n")
  end

  def wait_for(port, retries: 5)
    (1..retries).each do |attempt|
      TCPSocket.new(host, port).close
      break
    rescue Errno::ECONNREFUSED
      raise if attempt == retries

      sleep 1
      next
    end
  end
end

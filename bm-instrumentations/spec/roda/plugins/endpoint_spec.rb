# frozen_string_literal: true

require 'roda'
require 'bm/instrumentations/rack/endpoint'

RSpec.describe 'Roda::RodaPlugins::Endpoint', rack: true do
  let(:print_endpoint) do
    Class.new do
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env).tap do |resp|
          resp[1]['X-Endpoint'] = env[BM::Instrumentations::Rack::ENDPOINT]
        end
      end
    end
  end

  let(:api) do
    Class.new(::Roda) do
      def self.name
        'RodaAppTest'
      end

      plugin(:endpoint)

      endpoint def foo(reply)
        reply
      end

      def root
        'root'
      end
      endpoint :root

      route do |r|
        r.root { root }
        r.get('foo') { foo('bar') }
      end
    end
  end
  let(:app) do
    api.use print_endpoint
    api.app.freeze
  end

  it 'sets endpoint name to Rack env' do
    get '/foo'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('bar')
    expect(last_response['X-Endpoint']).to eq('RodaAppTest/foo')

    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('root')
    expect(last_response['X-Endpoint']).to eq('RodaAppTest/root')
  end
end

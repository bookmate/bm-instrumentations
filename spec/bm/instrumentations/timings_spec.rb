# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::Timings do
  let(:app) do
    cls = Class.new do
      def self.name
        'AppTest'
      end
    end
    cls.include described_class[:app_test, registry: registry]
    cls.class_exec do
      timings def foo(_first, second: nil)
        second
      end

      def fails
        raise(yield)
      end
      timings :fails
    end
    cls.new
  end

  it 'includes a timings module' do
    expect(app.method(:foo).source_location[0]).to be_end_with('bm/instrumentations/timings.rb')
    expect(app.method(:fails).source_location[0]).to be_end_with('bm/instrumentations/timings.rb')
  end

  it 'registers metrics in registry' do
    app
    expect(registry.get(:app_test_calls_total)).to be_kind_of(Prometheus::Client::Counter)
    expect(registry.get(:app_test_call_duration_seconds)).to be_kind_of(Prometheus::Client::Histogram)
  end

  context 'when included twice with same prefix' do
    let(:second_app) do
      cls = Class.new do
        def self.name
          'AppTest'
        end
      end
      cls.include described_class[:app_test, registry: registry]
      cls.new
    end

    it 'shares same metrics' do
      expect(second_app.class.timings_instrumentation.calls_total).to \
        eq(app.class.timings_instrumentation.calls_total)

      expect(second_app.class.timings_instrumentation.call_duration_seconds).to \
        eq(app.class.timings_instrumentation.call_duration_seconds)
    end
  end

  describe 'collect metrics' do
    let(:labels) { { class: 'AppTest', method: 'foo', status: 'success' } }

    before { expect(app.foo(1, second: 'bar')).to eq('bar') }

    it_behaves_like 'increments a counter', :app_test_calls_total
    it_behaves_like 'fills a histogram buckets', :app_test_call_duration_seconds
  end

  describe 'collect metrics', 'with an exception' do
    let(:labels) { { class: 'AppTest', method: 'fails', status: 'failure' } }

    before { expect { app.fails { 'boom' } }.to raise_error('boom') }

    it_behaves_like 'increments a counter', :app_test_calls_total
    it_behaves_like 'fills a histogram buckets', :app_test_call_duration_seconds
  end
end

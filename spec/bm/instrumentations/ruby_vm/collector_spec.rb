# frozen_string_literal: true

require 'bm/instrumentations'

RSpec.describe BM::Instrumentations::RubyVM::Collector do
  before do
    BM::Instrumentations::RubyVM.install(registry, enable_gc_profiler: true)
  end

  it 'registers metrics in registry' do
    expect(registry.get(:ruby_gc_time_seconds)).to be_kind_of(Prometheus::Client::Summary)
    expect(registry.get(:ruby_gc_heap_slots_size)).to be_kind_of(Prometheus::Client::Gauge)
    expect(registry.get(:ruby_gc_allocated_objects_total)).to be_kind_of(Prometheus::Client::Gauge)
    expect(registry.get(:ruby_gc_freed_objects_total)).to be_kind_of(Prometheus::Client::Gauge)
    expect(registry.get(:ruby_gc_counts_total)).to be_kind_of(Prometheus::Client::Gauge)
    expect(registry.get(:ruby_vm_global_cache_state)).to be_kind_of(Prometheus::Client::Gauge)
    expect(registry.get(:ruby_threads_count)).to be_kind_of(Prometheus::Client::Gauge)
  end

  describe '#update' do
    subject(:update) do
      (1..1_000_000).to_a.each { _1 }
      GC.start
      registry.update_custom_collectors
    end

    before { update }

    it 'increments a :ruby_gc_time_seconds summary' do
      expect(gauge_value(:ruby_gc_time_seconds)).to include('count' => 1.0, 'sum' => be_positive)
    end

    it 'increments a :ruby_gc_heap_slots_size gauge' do
      expect(gauge_value(:ruby_gc_heap_slots_size, slots: 'free')).to be_positive
      expect(gauge_value(:ruby_gc_heap_slots_size, slots: 'live')).to be_positive
    end

    it 'increments a :ruby_gc_allocated_objects_total gauge' do
      expect(gauge_value(:ruby_gc_allocated_objects_total)).to be_positive
    end

    it 'increments a :ruby_gc_freed_objects_total gauge' do
      expect(gauge_value(:ruby_gc_freed_objects_total)).to be_positive
    end

    it 'increments a :ruby_gc_counts_total gauge' do
      expect(gauge_value(:ruby_gc_counts_total, counts: 'minor')).to be_positive
      expect(gauge_value(:ruby_gc_counts_total, counts: 'major')).to be_positive
    end

    it 'increments a :ruby_vm_global_cache_state gauge', 'with method' do
      skip('Not for ruby3') if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0')

      expect(gauge_value(:ruby_vm_global_cache_state, cache: 'method')).to be_positive
    end

    it 'increments a :ruby_vm_global_cache_state gauge', 'with constant' do
      expect(gauge_value(:ruby_vm_global_cache_state, cache: 'constant')).to be_positive
    end

    it 'increments a :ruby_threads_count gauge' do
      expect(gauge_value(:ruby_threads_count)).to be_positive
    end
  end
end

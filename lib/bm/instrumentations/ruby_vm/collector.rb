# frozen_string_literal: true

require_relative '../internal/prometheus_registry_custom_collectors'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    # Collects Ruby VM and GC metrics
    module RubyVM
      # Collects Ruby VM and GC metrics
      #
      # @attr [MetricsCollection] metrics_collection
      class Collector
        attr_reader :metrics_collection

        SLOTS_FREE = { labels: { slots: 'free' } }.freeze
        SLOTS_LIVE = { labels: { slots: 'live' } }.freeze
        CACHE_METHOD = { labels: { cache: 'method' } }.freeze
        CACHE_CONSTANT = { labels: { cache: 'constant' } }.freeze
        MINOR_GC_COUNT = { labels: { counts: 'minor' } }.freeze
        MAJOR_GC_COUNT = { labels: { counts: 'major' } }.freeze

        # @param registry [Prometheus::Client::Registry]
        # @api private
        def initialize(registry)
          @metrics_collection = MetricsCollection.new(registry)
        end

        # @return [void]
        def update
          update_gc_profiler_total_time if GC::Profiler.enabled?
          update_gc_stats(::GC.stat)
          update_global_cache(::RubyVM.stat)
          metrics_collection.threads_count.set(::Thread.list.size)
        end

        # @return [Proc]
        def to_proc
          -> { update }
        end

        private

        # @param gc_stats [Hash<Symbol, Integer>]
        # @option gc_stats [Integer] :heap_free_slots
        # @option gc_stats [Integer] :heap_live_slots
        # @option gc_stats [Integer] :total_allocated_objects
        # @option gc_stats [Integer] :total_freed_objects
        # @option gc_stats [Integer] :minor_gc_count
        # @option gc_stats [Integer] :major_gc_count
        def update_gc_stats(gc_stats) # rubocop:disable Metrics/AbcSize
          metrics_collection.gc_heap_slots_size.set(gc_stats[:heap_free_slots], **SLOTS_FREE)
          metrics_collection.gc_heap_slots_size.set(gc_stats[:heap_live_slots], **SLOTS_LIVE)
          metrics_collection.gc_allocated_objects_total.set(gc_stats[:total_allocated_objects])
          metrics_collection.gc_freed_objects_total.set(gc_stats[:total_freed_objects])
          metrics_collection.gc_counts_total.set(gc_stats[:minor_gc_count], **MINOR_GC_COUNT)
          metrics_collection.gc_counts_total.set(gc_stats[:major_gc_count], **MAJOR_GC_COUNT)
        end

        # @param vm_stats [Hash<Symbol, Integer>]
        # @option vm_stats [Integer] :global_method_state
        # @option vm_stats [Integer] :global_constant_state
        def update_global_cache(vm_stats)
          return unless %i[global_method_state global_constant_state].all? { vm_stats.include?(_1) }

          metrics_collection.vm_global_cache_state.set(vm_stats[:global_method_state], **CACHE_METHOD)
          metrics_collection.vm_global_cache_state.set(vm_stats[:global_constant_state], **CACHE_CONSTANT)
        end

        # Records {GC::Profiler.total_time} if it's enabled
        #
        # By default {GC::Profile} is disabled and total time always zero, to get non zero values
        # the GC profiler should be enabled by calling {GC::Profiler.enable}
        def update_gc_profiler_total_time
          total_time = GC::Profiler.total_time
          metrics_collection.gc_time_seconds.observe(total_time.round(6))
        ensure
          GC::Profiler.clear
        end
      end

      # @param registry [Prometheus::Client::Registry] overrides the default registry
      # @param enable_gc_profiler [Boolean] turn on {GC::Profiler}
      # @return [void]
      def self.install(registry = nil, enable_gc_profiler: true)
        ::GC::Profiler.enable if enable_gc_profiler

        registry ||= Prometheus::Client.registry
        registry.add_custom_collector(&Collector.new(registry))
      end
    end
  end
end

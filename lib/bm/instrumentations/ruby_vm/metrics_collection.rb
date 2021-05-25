# frozen_string_literal: true

module BM
  module Instrumentations
    module RubyVM
      # A collection of Prometheus metrics for Ruby VM & GC
      #
      # @attr [Prometheus::Client::Summary] gc_time_seconds
      # @attr [Prometheus::Client::Gauge] gc_heap_slots_size
      # @attr [Prometheus::Client::Gauge] gc_allocated_objects_total
      # @attr [Prometheus::Client::Gauge] gc_freed_objects_total
      # @attr [Prometheus::Client::Gauge] gc_counts_total
      # @attr [Prometheus::Client::Gauge] vm_global_cache_state
      # @attr [Prometheus::Client::Gauge] threads_count
      class MetricsCollection
        include RegisterMetric

        attr_reader :gc_time_seconds, :gc_heap_slots_size, :gc_allocated_objects_total,
                    :gc_freed_objects_total, :gc_counts_total, :vm_global_cache_state, :threads_count

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          build_version(registry)
          build_gc_time_seconds(registry)
          build_gc_heap_slots_size(registry)
          build_gc_allocated_objects_total(registry)
          build_gc_freed_objects_total(registry)
          build_gc_counts_total(registry)
          build_vm_global_cache_state(registry)
          build_threads_count(registry)
        end

        private

        # @param registry [Prometheus::Client::Registry]
        def build_version(registry)
          version = register_metric(registry, :ruby_version) do |name|
            registry.gauge(
              name,
              docstring: 'The Ruby VM version',
              labels: %i[ruby version]
            )
          end
          version.set(1, labels: { ruby: RUBY_ENGINE, version: RUBY_ENGINE_VERSION })
        end

        # @param registry [Prometheus::Client::Registry]
        def build_gc_time_seconds(registry)
          @gc_time_seconds = register_metric(registry, :ruby_gc_time_seconds) do |name|
            registry.summary(
              name,
              docstring: 'The total time that Ruby GC spends for garbage collection in seconds'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_gc_heap_slots_size(registry)
          @gc_heap_slots_size = register_metric(registry, :ruby_gc_heap_slots_size) do |name|
            registry.gauge(
              name,
              docstring: 'The size of available heap slots of Ruby GC partitioned by slots type',
              labels: %i[slots]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_gc_allocated_objects_total(registry)
          @gc_allocated_objects_total = register_metric(registry, :ruby_gc_allocated_objects_total) do |name|
            registry.gauge(
              name,
              docstring: 'The total number of allocated objects by Ruby GC'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_gc_freed_objects_total(registry)
          @gc_freed_objects_total = register_metric(registry, :ruby_gc_freed_objects_total) do |name|
            registry.gauge(
              name,
              docstring: 'The total number of freed objects by Ruby GC'
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_gc_counts_total(registry)
          @gc_counts_total = register_metric(registry, :ruby_gc_counts_total) do |name|
            registry.gauge(
              name,
              docstring: 'The total number of Ruby GC counts partitioned by counts type',
              labels: %i[counts]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_vm_global_cache_state(registry)
          @vm_global_cache_state = register_metric(registry, :ruby_vm_global_cache_state) do |name|
            registry.gauge(
              name,
              docstring: 'The Ruby VM global cache state (version) for methods and constants,' \
                         ' partitioned by cache type',
              labels: %i[cache]
            )
          end
        end

        # @param registry [Prometheus::Client::Registry]
        def build_threads_count(registry)
          @threads_count = register_metric(registry, :ruby_threads_count) do |name|
            registry.gauge(
              name,
              docstring: 'The number of running threads'
            )
          end
        end
      end
    end
  end
end

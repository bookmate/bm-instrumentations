# frozen_string_literal: true

require_relative 'linux/proc_status'
require_relative 'linux/proc_fd'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    # Collects Ruby VM and GC metrics
    module Process
      # :nodoc:
      module LinuxCollector
        def update
          metrics_collection.process_open_fds_count.set(linux_proc_fd.count)
          metrics_collection.process_rss_memory_bytes_count.set(linux_proc_status.rss_memory_bytes)
        end
      end

      # Collects process RSS memory and the number of open file descriptors
      #
      # It it a custom collector that poll metrics periodically and currently working only if the
      # management server is used.
      #
      # @example Usage
      #   BM::Instrumentations::Process.install
      #
      # @attr [MetricsCollection] metrics_collection
      # @attr [Linux::ProcStatus] linux_proc_status
      # @attr [Linux::ProcFD] linux_proc_fd
      # @api private
      class Collector
        prepend LinuxCollector if RUBY_PLATFORM.include?('linux')

        attr_reader :metrics_collection, :linux_proc_status, :linux_proc_fd

        # @param registry [Prometheus::Client::Registry]
        def initialize(registry)
          @metrics_collection = MetricsCollection.new(registry)
          @linux_proc_status = Linux::ProcStatus.new
          @linux_proc_fd = Linux::ProcFD.new
        end

        # @return [void]
        def update; end
      end

      # @param registry [Prometheus::Client::Registry] overrides the default registry
      # @param enable_gc_profiler [Boolean] turn on {GC::Profiler}
      # @return [void]
      def self.install(registry = nil)
        registry ||= Prometheus::Client.registry
        registry.add_custom_collector(&Collector.new(registry))
      end
    end
  end
end

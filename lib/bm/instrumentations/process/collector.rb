# frozen_string_literal: true

require_relative '../internal/prometheus_registry_custom_collectors'
require_relative 'linux/proc_status'
require_relative 'linux/proc_fd'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    # Collects process RSS memory and the number of open file descriptors
    module Process
      # @api private
      module LinuxCollector
        # :nodoc:
        def call
          metrics_collection.process_open_fds_count.set(linux_proc_fd.count)
          metrics_collection.process_rss_memory_bytes_count.set(linux_proc_status.rss_memory_bytes)
        end

        # @return [Boolean]
        def enabled?
          true
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
          return unless enabled?

          @metrics_collection = MetricsCollection.new(registry)
          @linux_proc_status = Linux::ProcStatus.new
          @linux_proc_fd = Linux::ProcFD.new
        end

        # Is this collector should be running
        # @return [Boolean]
        def enabled?
          false
        end

        # @return [void]
        def call; end
      end

      # @param registry [Prometheus::Client::Registry] overrides the default registry
      # @return [void]
      def self.install(registry = nil)
        registry ||= Prometheus::Client.registry
        collector = Collector.new(registry)
        registry.add_custom_collector(collector) if collector.enabled?
      end
    end
  end
end

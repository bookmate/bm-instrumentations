# frozen_string_literal: true

require 'puma'

require_relative '../internal/prometheus_registry_custom_collectors'
require_relative 'metrics_collection'
require_relative 'tcp_info'

module BM
  module Instrumentations
    # Puma metrics collector, collects thread pool stats and optionally socket backlog stats.
    #
    # It it a custom collector that poll metrics periodically and currently working only if the
    # management server is used.
    module Puma
      # Puma metrics collector, collects thread pool stats and optionally socket backlog stats
      #
      # @attr [MetricsCollection] metrics_collection
      # @attr [Puma::Launcher] launcher
      # @attr [TcpInfo] tcp_info
      #
      # @api private
      class Collector
        attr_reader :metrics_collection, :launcher, :tcp_info

        # @param registry [Prometheus::Client::Registry]
        # @param launcher [Puma::Launcher]
        def initialize(registry:, launcher:)
          @metrics_collection = MetricsCollection.new(registry)
          @launcher = launcher
          @tcp_info = TcpInfo.new

          metrics_collection.server_version(::Puma::Server::VERSION)
        end

        # @return [Proc]
        def to_proc
          -> { update }
        end

        # Updates Puma metrics in the registry
        def update
          metrics_collection.update_stats(launcher.stats)
          return unless tcp_info.available?

          launcher.binder.ios.each_with_index do |io, index|
            metrics_collection.update_backlog(listener: index, backlog: tcp_info.of(io))
          end
        end
      end

      # Puma metrics collector, collects thread pool stats and optionally socket backlog stats
      #
      # @param launcher [Puma::Launcher]
      # @param registry [Prometheus::Client::Registry, nil]
      def self.install(launcher, registry: nil)
        registry ||= Prometheus::Client.registry
        registry.add_custom_collector(&Collector.new(registry: registry, launcher: launcher))
      end
    end
  end
end

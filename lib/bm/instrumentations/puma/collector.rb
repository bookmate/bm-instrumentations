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

        # Updates Puma metrics in the registry
        def call
          metrics_collection.update_stats(launcher.stats)
          return unless tcp_info.available?

          launcher.binder.ios.each_with_index do |io, index|
            metrics_collection.update_backlog(listener: index, backlog: tcp_info.of(io))
          end
        end
      end

      # Installs a custom collector into {Prometheus::Registry}
      #
      # @param launcher [Puma::Launcher]
      # @param registry [Prometheus::Client::Registry, nil]
      # @return [void]
      def self.install(launcher, registry: nil)
        registry ||= Prometheus::Client.registry
        registry.add_custom_collector(Collector.new(registry: registry, launcher: launcher))
      end
    end
  end
end

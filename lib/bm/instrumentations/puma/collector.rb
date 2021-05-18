# frozen_string_literal: true

require 'socket'
require 'puma'

require 'tcp_server_socket_backlog/tcp_server_socket_backlog'
require 'bm/instrumentations/internal/prometheus_registry_custom_collectors'
require_relative 'metrics_collection'

module BM
  module Instrumentations
    module Puma
      # @attr [MetricsCollection] metrics_collection
      # @attr [Puma::Launcher] launcher
      # @attr [Boolean] is_socket_backlog
      #
      # @api private
      class Collector
        attr_reader :metrics_collection, :launcher, :is_socket_backlog

        # @param registry [Prometheus::Client::Registry]
        # @param launcher [Puma::Launcher]
        def initialize(registry:, launcher:)
          @metrics_collection = MetricsCollection.new(registry)
          @launcher = launcher

          # TCP_INFO with backlog statistics is Linux only
          @is_socket_backlog = TCPServer.method_defined?(:socket_backlog)

          metrics_collection.server_version(::Puma::Server::VERSION)
        end

        # @return [Proc]
        def to_proc
          -> { update }
        end

        # Updates Puma metrics in the registry
        def update
          metrics_collection.update_stats(launcher.stats)
          return unless is_socket_backlog

          launcher.binder.ios.each_with_index do |io, index|
            backlog = io.socket_backlog
            metrics_collection.update_backlog(listener: index, backlog: backlog) if backlog
          end
        end

        # @param launcher [Puma::Launcher]
        # @param registry [Prometheus::Client::Registry, nil]
        def self.install(launcher, registry: nil)
          registry ||= Prometheus::Client.registry
          registry.add_custom_collector(&Collector.new(registry: registry, launcher: launcher))
        end
      end
    end
  end
end

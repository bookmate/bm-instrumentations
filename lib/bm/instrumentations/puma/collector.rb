# frozen_string_literal: true

require 'socket'
require 'prometheus/client'
require 'tcp_server_socket_backlog_size'

module BM
  module Instrumentations
    module Puma
      # @attr [MetricsCollection] metrics_collection
      # @attr [Puma::Launcher] launcher
      # @attr [Boolean] is_socket_backlog
      class Collector
        attr_reader :metrics_collection, :launcher, :is_socket_backlog

        # @param registry [Prometheus::Client::Registry]
        # @param launcher [Puma::Launcher]
        def initialize(registry:, launcher:)
          @metrics_collection = MetricsCollection.new(registry)
          @launcher = launcher

          # TCP_INFO with backlog statistics is Linux only
          @is_socket_backlog = TCPServer.method_defined?(:socket_backlog_size)
        end

        # Updates Puma metrics in the registry
        def update
          metrics_collection.update_stats(launcher.stats)
          return unless is_socket_backlog

          launcher.binder.ios.each_with_index do |io, index|
            backlog = io.socket_backlog_size
            metrics_collection.update_backlog(listener: index, backlog: backlog) if backlog
          end
        end
      end
    end
  end
end

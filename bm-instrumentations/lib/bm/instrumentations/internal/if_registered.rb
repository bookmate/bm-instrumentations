# frozen_string_literal: true

module BM
  module Instrumentations
    # Checks if a metric already exist in registry and yield
    # a block with the registered metric
    #
    # @api private
    module IfRegistered
      # @param registry [Prometheus::Client::Registry]
      # @param name [Symbol]
      def if_registered(registry, name)
        return unless registry.exist?(name)

        yield registry.get(name)
      end
    end
  end
end

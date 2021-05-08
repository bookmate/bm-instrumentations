# frozen_string_literal: true

require 'bm/instrumentations/rack/endpoint'

class Roda
  # :nodoc:
  module RodaPlugins
    # The `endpoint` plugin adds an endpoint name to the Rack's request env.
    #
    # Roda lacks of "controller and action" abstractions, so it cannot be obtain a some useful
    # information about who was handled a request. This plugin fixes the issue by exporting
    # an endpoint name (a function which handled a request) to the Rack's request env as a
    # `x.rack.endpoint` key.
    #
    # @example Apply plugin
    #   class API < Roda
    #     plugin(:endpoint)
    #
    #     endpoint def pong
    #       'Pong'
    #     end
    #
    #     route do |r|
    #       r.get('ping') { pong }
    #     end
    #   end
    module Endpoint
      # @param app [Any]
      # @param options [Hash]
      def self.configure(app)
        app.extend ClassMethods
      end

      # Exports the :endpoint function's decorator
      module ClassMethods
        # @param method_name [Symbol]
        def endpoint(method_name)
          endpoint_name = "#{name}/#{method_name}"
          prepend(Module.new do
            define_method(method_name) do |*args, **kwargs, &block|
              request.env[BM::Instrumentations::Rack::ENDPOINT] = endpoint_name
              super(*args, **kwargs, &block)
            end
          end)
        end
      end
    end

    register_plugin(:endpoint, Endpoint)
  end
end

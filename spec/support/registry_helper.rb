# frozen_string_literal: true

RSpec.configure do |config|
  config.include(Module.new do
    def self.included(base)
      base.instance_eval do
        let(:registry) { Prometheus::Client::Registry.new }
      end
    end

    # @return [Float]
    def counter_value(name, labels = {})
      registry.get(name)&.get(labels: labels) || 0.0
    end
    alias_method :gauge_value, :counter_value

    # @return [Hash<String, Float>]
    def histogram_value(name, labels = {})
      registry.get(name)&.get(labels: labels) || {}
    end

    # @return [Hash]
    def metric_values(name)
      registry.get(name)&.values || {}
    end
  end)
end

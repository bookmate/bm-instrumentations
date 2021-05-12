# frozen_string_literal: true

require 'rspec/expectations'

RSpec.configure do |config|
  config.include(Module.new do
    extend RSpec::Matchers::DSL

    matcher :be_ok do
      match { |actual| actual.is_a?(Net::HTTPOK) }
    end

    matcher :be_not_found do
      match { |actual| actual.is_a?(Net::HTTPNotFound) }
    end

    matcher :have_content_type do |expected|
      match { |actual| actual['Content-Type'] == expected }

      failure_message do |actual|
        "expected that #{actual['Content-Type'].inspect} is equals to #{expected.inspect}"
      end
    end

    matcher :have_body do |expected|
      match { |actual| actual.body.include? expected }

      failure_message do |actual|
        "expected that [#{actual.body}]\n" \
      "contains [#{expected}]"
      end
    end
  end, net_http: true)
end

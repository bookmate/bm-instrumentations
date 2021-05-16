# frozen_string_literal: true

require 'rspec_junit_formatter'

RSpec.configure do |config|
  test_suite = ENV.fetch('TEST_SUITE', 'default')

  config.add_formatter('progress')
  config.add_formatter(RSpecJUnitFormatter, File.expand_path("../reports/junit/#{test_suite}.xml", __dir__))
end

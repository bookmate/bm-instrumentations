# frozen_string_literal: true

require 'bundler'

require_relative 'support/simplecov_start' if ENV.fetch('SIMPLECOV', '0') != '0'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require_relative 'support/rack_test_helper'
require_relative 'support/registry_helper'
require_relative 'support/shared_examples'

# frozen_string_literal: true

require 'bundler'

require_relative 'setup/simplecov'
require_relative 'setup/rspec_formatters'

RSpec.configure do |config|
  config.filter_run_excluding(integration: true)
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand(config.seed)

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require_relative 'support/rack_test_helper'
require_relative 'support/registry_helper'
require_relative 'support/non_listening_port_helper'
require_relative 'support/net_http_matchers'
require_relative 'support/shared_examples'

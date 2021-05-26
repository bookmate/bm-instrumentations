# frozen_string_literal: true

unless ENV.fetch('SIMPLECOV', '').empty?
  require 'simplecov'
  require 'simplecov_json_formatter'

  SimpleCov.formatters = [
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ]

  test_suite = ENV.fetch('TEST_SUITE', 'default')
  SimpleCov.command_name test_suite
  SimpleCov.coverage_dir(File.expand_path("../../coverage/#{test_suite}", __dir__))

  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/lib/bm/instrumentations/version.rb'
    track_files 'lib/**/*.rb'
  end
end

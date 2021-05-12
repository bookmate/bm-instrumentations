# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.formatters = [
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::HTMLFormatter
]

command_name = ENV.fetch('SIMPLECOV_COMMAND_NAME', '')
command_name = 'unit' if command_name.empty?
SimpleCov.command_name command_name
SimpleCov.coverage_dir(File.expand_path("../../coverage/#{command_name}", __dir__))

SimpleCov.start do
  add_filter '/spec/'
  track_files 'lib/**/*.rb'
end

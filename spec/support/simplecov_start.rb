# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.formatters = [
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::HTMLFormatter
]

SimpleCov.start do
  add_filter '/spec/'
  track_files 'lib/**/*.rb'
end

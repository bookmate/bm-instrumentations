# frozen_string_literal: true

namespace :simplecov do
  desc 'Merge Coverage Reports'
  task :merge do
    next if ENV.fetch('SIMPLECOV', '').empty?

    files = Dir['coverage/*/.resultset.json']
    next if files.empty?

    require 'simplecov'
    require 'simplecov_json_formatter'

    SimpleCov.collate files do
      formatter SimpleCov::Formatter::MultiFormatter.new(
        [SimpleCov::Formatter::JSONFormatter, SimpleCov::Formatter::HTMLFormatter]
      )
    end
  end
end

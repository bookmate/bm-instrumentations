# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new :rubocop do |t|
  formatters = %w[--format progress --format RuboCop::Formatter::CheckstyleFormatter]
  requires = %w[--require rubocop/formatter/checkstyle_formatter]
  out = %w[--out spec/reports/checkstyle/rubocop.xml]
  t.options = requires + formatters + out
end

task default: :spec

desc 'Run rubocop and when tests'
task ci: %i[rubocop spec]

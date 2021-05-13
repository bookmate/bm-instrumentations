# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/extensiontask'

Rake.add_rakelib 'lib/tasks/**'

Rake::ExtensionTask.new 'tcp_server_socket_backlog' do |ext|
  ext.lib_dir = 'lib/tcp_server_socket_backlog'
end

RuboCop::RakeTask.new :rubocop do |t|
  formatters = %w[--format progress --format RuboCop::Formatter::CheckstyleFormatter]
  requires = %w[--require rubocop/formatter/checkstyle_formatter]
  out = %w[--out spec/reports/checkstyle/rubocop.xml]
  t.options = requires + formatters + out
end

desc 'Run RSpec code examples'
task default: %i[spec:unit]

desc 'Run rubocop, then tests, then merge coverage reports'
task ci: %i[rubocop spec:unit spec:integrations simplecov:merge]

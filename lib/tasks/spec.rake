# frozen_string_literal: true

require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit)

  desc 'Run Integrations Specs'
  task :integrations do
    Dir['spec/integrations/**/*_spec.rb'].each_with_index do |file, idx|
      env = %W[SIMPLECOV=#{ENV['SIMPLECOV']} TEST_SUITE=integration-#{idx}]
      sh "#{env.join(' ')} bundle exec rspec --tag integration #{file}"
    end
  end
end

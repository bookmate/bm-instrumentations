# frozen_string_literal: true

require 'rspec/core/rake_task'

namespace :spec do
  RSpec::Core::RakeTask.new(:unit)

  desc 'Run Integrations Specs'
  task :integrations do
    Dir['spec/integrations/**/*_spec.rb'].each_with_index do |file, idx|
      env = ["SIMPLECOV=#{ENV['SIMPLECOV']}"]
      env << ["SIMPLECOV_COMMAND_NAME=integration-#{idx}"]
      env << ['INTEGRATION_SPECS=1']
      sh "#{env.join(' ')} bundle exec rspec #{file}"
    end
  end
end

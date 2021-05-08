# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bm/instrumentations/version'

Gem::Specification.new do |spec|
  spec.name          = 'bm-instrumentations'
  spec.version       = BM::Instrumentations::VERSION
  spec.authors       = ['Dmitry Galinsky']
  spec.email         = ['dima@bookmate.com']

  spec.summary       = 'Provides Prometheus metrics collectors and integrations for Sequel, Rack, S3, Roda and etc'
  spec.homepage      = 'https://github.com/bookmate/backend-commons/bm-instrumentations'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://nexus.bookmate.services'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'prometheus-client', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'rspec', '~> 3.10'

  spec.add_development_dependency 'rubocop', '= 1.14.0'
  spec.add_development_dependency 'rubocop-checkstyle_formatter', '= 0.4.0'
  spec.add_development_dependency 'rubocop-performance', '= 1.11.3'
  spec.add_development_dependency 'rubocop-rake', '= 0.5.1'
  spec.add_development_dependency 'rubocop-rspec', '= 2.3.0'

  spec.add_development_dependency 'rspec_junit_formatter', '= 0.4.1'
  spec.add_development_dependency 'simplecov', '= 0.21.2'

  spec.add_development_dependency 'aws-sdk-s3', '~> 1.94' # aws
  spec.add_development_dependency 'mysql2', '~> 0.5' # sequel
  spec.add_development_dependency 'rack', '~> 2.2' # rack
  spec.add_development_dependency 'rack-test', '~> 1.1' # rack
  spec.add_development_dependency 'roda', '~> 3.43' # roda
  spec.add_development_dependency 'sequel', '~> 5.44' # sequel
end

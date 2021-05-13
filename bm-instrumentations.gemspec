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

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://nexus.bookmate.services'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib ext]

  spec.add_dependency 'prometheus-client', '~> 2.1'
end

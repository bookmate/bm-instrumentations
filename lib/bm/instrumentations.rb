# frozen_string_literal: true

require 'prometheus/client'
require 'bm/instrumentations/version'

module BM
  # Provides Prometheus metrics collectors and integrations for Sequel,
  # Rack, S3, Roda and etc.
  module Instrumentations
    autoload :RegisterMetric, 'bm/instrumentations/internal/register_metric'
    autoload :Stopwatch,      'bm/instrumentations/internal/stopwatch'
    autoload :Timings,        'bm/instrumentations/timings/timings'
    autoload :Aws,            'bm/instrumentations/aws/collector'
    autoload :Management,     'bm/instrumentations/management/server'
    autoload :Rack,           'bm/instrumentations/rack/middleware'
    autoload :RubyVM,         'bm/instrumentations/ruby_vm/collector'
    autoload :Process,        'bm/instrumentations/process/collector'
    autoload :Puma,           'bm/instrumentations/puma/collector'
  end
end

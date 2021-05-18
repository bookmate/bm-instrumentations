# frozen_string_literal: true

require 'prometheus/client'
require 'bm/instrumentations/version'

module BM
  # :nodoc:
  module Instrumentations
    autoload :RegisterMetric, 'bm/instrumentations/internal/register_metric'
    autoload :Stopwatch,      'bm/instrumentations/internal/stopwatch'
    autoload :Timings,        'bm/instrumentations/timings/timings'
    autoload :Aws,            'bm/instrumentations/aws/collector'
    autoload :Management,     'bm/instrumentations/management/server'
    autoload :Rack,           'bm/instrumentations/rack/middleware'
  end
end

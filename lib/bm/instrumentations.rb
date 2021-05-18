# frozen_string_literal: true

require 'bm/instrumentations/version'

module BM
  # :nodoc:
  module Instrumentations
    autoload :RegisterMetric, 'bm/instrumentations/internal/register_metric'
    autoload :Stopwatch,      'bm/instrumentations/internal/stopwatch'
    autoload :Timings,        'bm/instrumentations/timings'

    autoload :Aws,            'bm/instrumentations/aws/collector'
    autoload :Management,     'bm/instrumentations/management/server'

    module Rack
      autoload :Collector,         'bm/instrumentations/rack/collector'
      autoload :ENDPOINT,          'bm/instrumentations/rack/endpoint'
      autoload :MetricsCollection, 'bm/instrumentations/rack/metrics_collection'
    end

    module Sequel
      autoload :MetricsCollection, 'bm/instrumentations/sequel/metrics_collection'
    end
  end
end

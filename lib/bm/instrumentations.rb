# frozen_string_literal: true

require 'bm/instrumentations/version'

module BM
  # :nodoc:
  module Instrumentations
    autoload :RegisterMetric, 'bm/instrumentations/internal/register_metric'
    autoload :Stopwatch,      'bm/instrumentations/internal/stopwatch'
    autoload :Timings,        'bm/instrumentations/timings'

    module Aws
      autoload :Collector,         'bm/instrumentations/aws/collector'
      autoload :MetricsCollection, 'bm/instrumentations/aws/metrics_collection'
    end

    module Rack
      autoload :Collector,         'bm/instrumentations/rack/collector'
      autoload :ENDPOINT,          'bm/instrumentations/rack/endpoint'
      autoload :MetricsCollection, 'bm/instrumentations/rack/metrics_collection'
    end

    module Sequel
      autoload :MetricsCollection, 'bm/instrumentations/sequel/metrics_collection'
    end

    module Management
      autoload :Server,            'bm/instrumentations/management/server'
    end
  end
end

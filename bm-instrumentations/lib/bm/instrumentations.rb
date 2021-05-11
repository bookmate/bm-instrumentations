# frozen_string_literal: true

require 'bm/instrumentations/version'

module BM
  # :nodoc:
  module Instrumentations
    autoload :IfRegistered, 'bm/instrumentations/internal/if_registered'
    autoload :Stopwatch,    'bm/instrumentations/internal/stopwatch'
    autoload :Timings,      'bm/instrumentations/timings'

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
  end
end

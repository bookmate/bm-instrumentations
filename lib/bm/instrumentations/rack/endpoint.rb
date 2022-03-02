# frozen_string_literal: true

module BM
  module Instrumentations
    class Rack
      # Is a Rack env key for a name of an endpoint which served a request
      ENDPOINT = 'x.rack.endpoint'

      # Is a Rack env which overrides HTTP status code for metrics
      STATUS_CODE_INTERNAL = 'x.rack.status_code.internal'
    end
  end
end

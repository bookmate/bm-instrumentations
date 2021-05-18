# frozen_string_literal: true

module BM
  module Instrumentations
    class Rack
      # Is a Rack env key for a name of an endpoint which served a request
      ENDPOINT = 'x.rack.endpoint'
    end
  end
end

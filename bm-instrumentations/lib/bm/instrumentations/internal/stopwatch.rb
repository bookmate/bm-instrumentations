# frozen_string_literal: true

module BM
  module Instrumentations
    # An object that measures elapsed time in seconds.
    #
    # It is useful to measure elapsed time using this class instead of direct calls to `clock_gettime`.
    class Stopwatch
      def initialize
        @start_time = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
      end
      private_class_method :new

      # Creates (and starts) a new stopwatch using `Process.clock_gettime`
      #
      # @return [StopWatch] a started stop watch
      def self.started
        new
      end

      # Returns the current elapsed time in seconds shown on this stopwatch
      #
      # @return [Float] elapsed time in seconds
      def elapsed
        ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - @start_time
      end
      alias to_f elapsed
    end
  end
end

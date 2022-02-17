# frozen_string_literal: true

module BM
  module Instrumentations
    module Process
      # :nodoc:
      module Linux
        # Reads RSS process memory in bytes from `/proc/$$/status`
        #
        # @api private
        # @attr [String] status_file
        class ProcStatus
          attr_reader :status_file

          # Is a regexp for searching RSS memory value
          RSS_RE = /\AVmRSS:\s*(\d+) kB/.freeze

          # :nodoc:
          # @param status_file [String, nil]
          def initialize(status_file: nil)
            @status_file = status_file || "/proc/#{::Process.pid}/status"
          end

          # Returns the process's RSS memory in bytes or zero if unable to read
          #
          # @return [Integer]
          def rss_memory_bytes
            status = File.open(status_file, 'r') { _1.read_nonblock(4096) }
            start_at = status.index('VmRSS:')
            return 0 unless start_at

            match = RSS_RE.match(status[start_at..])
            return 0 unless match

            match[1].to_i * 1024
          end
        end
      end
    end
  end
end

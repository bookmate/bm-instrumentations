# frozen_string_literal: true

module BM
  module Instrumentations
    module Process
      # :nodoc:
      module Linux
        # Returns the number of open file descriptors for the current process
        #
        # @api private
        # @attr [String] status_file
        class ProcFD
          attr_reader :fd_dir

          # :nodoc:
          # @param fd_dir [String, nil]
          def initialize(fd_dir: nil)
            @fd_dir = fd_dir || "/proc/#{::Process.pid}/fd"
          end

          # Returns the number of open file descriptors for the current process
          #
          # @return [Integer]
          def count
            Dir.children(fd_dir).size
          end
        end
      end
    end
  end
end

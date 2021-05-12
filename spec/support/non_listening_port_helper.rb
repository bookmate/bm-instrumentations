# frozen_string_literal: true

require 'socket'

RSpec.configure do |config|
  config.include(Module.new do
    # Returns a free TCP port that never listened
    #
    # @return [Integer]
    def non_listening_port
      @non_listening_port ||= begin
        server = TCPServer.new('127.0.0.1', 0)
        server.addr[1]
      ensure
        server&.close
      end
    end
  end)
end

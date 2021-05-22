# frozen_string_literal: true

require 'socket'

module BM
  module Instrumentations
    module Puma
      # Invokes getsockopt(TCP_INFO) for {TCPServer} socket and returns the maximum backlog size and the current
      # backlog
      class TcpInfo
        # struct tcp_info {
        #  __u8    tcpi_state;
        #  __u8    tcpi_ca_state;
        #  __u8    tcpi_retransmits;
        #  __u8    tcpi_probes;
        #  __u8    tcpi_backoff;
        #  __u8    tcpi_options;
        #  __u8    tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;
        #
        #  __u32   tcpi_rto;
        #  __u32   tcpi_ato;
        #  __u32   tcpi_snd_mss;
        #  __u32   tcpi_rcv_mss;
        #
        #  __u32   tcpi_unacked;
        #  __u32   tcpi_sacked;
        #  .....
        #                             !! here are: tcpi_unacked and tcpi_sacked
        UNPACK = "#{'C' * 8}#{'L' * 4}LL"

        def initialize
          @available = ::Socket.const_defined?(:TCP_INFO) && Socket.const_defined?(:IPPROTO_TCP)
        end

        def available?
          @available
        end

        # @param tcp_socket [TCPSocket]
        # @return [Hash<Symbol, Int>]
        def of(tcp_socket)
          tcp_info = tcp_socket.getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO)
          data = tcp_info.unpack(UNPACK)

          {
            backlog_size: data[12],
            backlog_max_size: data[13]
          }
        end
      end
    end
  end
end

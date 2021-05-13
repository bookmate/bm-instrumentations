# frozen_string_literal: true

require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

create_header
create_makefile 'tcp_server_socket_backlog_size'

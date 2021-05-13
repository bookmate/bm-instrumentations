# frozen_string_literal: true

bind 'tcp://[::]:3000?backlog=20'
threads 4, 4
plugin :management_server

app(lambda do |_|
  [200, {}, ['hello']]
end)

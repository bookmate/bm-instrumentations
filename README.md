[![Build](https://github.com/bookmate/bm-instrumentations/actions/workflows/main.yml/badge.svg)](https://github.com/bookmate/bm-instrumentations/actions/workflows/main.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/f411d33e684d199b1a76/maintainability)](https://codeclimate.com/github/bookmate/bm-instrumentations/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f411d33e684d199b1a76/test_coverage)](https://codeclimate.com/github/bookmate/bm-instrumentations/test_coverage)

# Bm::Instrumentations

Provides Prometheus metrics collectors and integrations for Sequel,
Rack, S3, Roda and etc.

* [Installation](#installation)
* [Rack Metrics](#rack-metrics)
* [Sequel Metrics Collector](#sequel-metrics-collector)
* [AWS Client Metrics](#aws-client-metrics)
* [Ruby Method Metrics Collector](#ruby-methods-metrics-collector)
* [Endpoint Name Roda Plugin](#endpoint-name-roda-plugin)
* [Management Server Puma plugin](#management-server-puma-plugin)

<hr>

## Installation

Add this line to your application’s Gemfile:

``` ruby
gem 'bm-instrumentations'
```

And then execute:

``` shell
$ bundle
```

Or install it yourself as:

``` shell
$ gem install bm-instrumentations
```

<hr>

## Rack Metrics

`BM::Instrumentations::Rack` is a Rack middleware that collect metrics for HTTP request and 
responses.

```ruby
# config.ru
require 'bm/instrumentations'
use BM::Instrumentations::Rack, exclude_path: %w[/metrics /ping]
```

The middleware has some optional parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
|`exclude_path` | `String`<br>`Array<String>` | a list of ignored path names, for that paths the metrics won’t be record |
|`registry` | `Prometheus::Client::Registry` | override the default Prometheus registry |

#### Collected metrics

| Metrics | Type | Labels | Description |
|---------|------|--------|-------------|
| `http_server_requests_total` | counter |  `method`<br>`path`<br>`status`<br>`status_code` | the total number of HTTP requests handled by the Rack application |
| `http_server_exceptions_total` | counter | `method`<br>`path`<br>`exception` | the total number of uncaught exceptions raised by the Rack application |
| `http_server_request_duration_seconds` | histogram | `method`<br>`path`<br>`status`<br>`status_code` | the HTTP response times in seconds of the Rack application |

#### Labels

* `method` is a HTTP method name such as `GET` or `POST`
* `path` is an endpoint’s path that handled a request, `none` if undefined
* `status` is a cumulative value of a HTTP status code like `2xx` or `5xx`
* `status_code` is a HTTP status code from response such as `200` or `500` 
* `exception` is an uncaught exception class name such as `RuntimeError` or
`Errno::ENOENT`

<hr>

## Sequel Metrics Collector

`Sequel::Extensions::PrometheusInstrumentation` is a Sequel extension that instrument a database queries and write
metrics into Prometheus.

```ruby
# Apply an extension
db = Sequel.connect(database_url)
db.extension(:prometheus_instrumentation)
```

#### Collected metrics

| Metrics | Type | Labels | Description |
|---------|------|--------|-------------|
| `sequel_queries_total` | counter | `database`<br>`query`<br>`status` | how many Sequel queries processed, partitioned by status |
| `sequel_query_duration_seconds` | histogram | `database`<br>`status`<br>`status` | the duration in seconds that a Sequel queries spent |

#### Labels

* `database` is a database name that a connection connected
* `query` is a query statement name such as `select`, `update`
* `status` one of `success` or `failure`

<hr>

## AWS Client Metrics

`BM::Instrumentations::Aws.plugin` is an AWS client plugin that instrument API calls and write metrics into 
Prometheus.

```ruby
require 'bm/instrumentations'

# Apply a plugin
Aws::S3::Client.add_plugin(BM::Instrumentations::Aws.plugin)
s3_client = Aws::S3::Client.new(options)
```

#### Collected metrics
 
| Metrics | Type | Labels | Description |
|---------|------|--------|-------------|
| `aws_sdk_client_requests_total` | counter | `service`<br>`api`<br>`status` | the total number of successful or failed API calls from AWS client to AWS services |
| `aws_sdk_client_request_duration_seconds` | histogram | `service`<br>`api`<br>`status` | the total time in seconds for the AWS Client to make a call to AWS services |
| `aws_sdk_client_retries_total` | counter | `service`<br>`api` | the total number retries of failed API calls from AWS client to AWS services |
| `aws_sdk_client_exceptions_total` | counter | `service`<br>`api`<br>`exception` | the total number of AWS API calls that fail |

#### Labels

* `service` is an AWS service name such as `S3`
* `api` is an AWS api method method such as `ListBuckets` or `GetObject`
* `status` is an HTTP status code returned by API call such as `200` or `500`
* `exception` is an exception class name such as `Seahorse::Client::NetworkingError`

<hr>

## Ruby Methods Metrics Collector

`BM::Instrumentations::Timings` is an observer that watch on specified ruby method and write metrics about the method
invocations.

```ruby
require 'bm/instrumentations'

class QueryUsers
  include BM::Instrumentations::Timings[:user_queries] # (1)
  
  def query_one(params)
    # ... any ruby code to instrument ...
  end
  timings :query_one # (2)
  
  def query_all(params)
    # ... any ruby code to instrument ...
  end
  timings :query_all # (2)
end
```

1. Includes a module with the `user_queries` metrics prefix, so each metric will have the `user_queries_` prefix
2. Attach to methods, each time when any observed method invokes a corresponding counter and a histogram 
   will be updated
   
#### Collected metrics

| Metrics | Type | Labels | Description |
|---------|------|--------|-------------|
| `<metrics_prefix>_calls_total` | counter | `class`<br>`method`<br>`status` | the total number of of successful or failed calls by ruby's method |
| `<metrics_prefix>_call_duration_seconds` | histogram | `class`<br>`method`<br>`status` | the time in seconds which spent at ruby's method calls |

#### Labels

* `class` is a ruby class where the module included
* `method` is an observed ruby's method name 
* `status` is one of `success` or `failure`

<hr>

# Endpoint Name Roda plugin

The `endpoint` plugin adds an endpoint name to the Rack's request env.

Roda lacks of "controller and action" abstractions, so it cannot be obtain a some useful
information about who was handled a request. This plugin fixes the issue by exporting
an endpoint name (a function which handled a request) to the Rack's request env as a
`x.rack.endpoint` key.

This plugin is useful with `BM::Instrumentations::Rack::Collector`. When applied the rack 
collector could be able to determine which function handled a request and correctly writes a 
`path` label to metrics.

```ruby
# Apply a plugin
class API < Roda
  plugin(:endpoint) # (1)

  endpoint def pong # (2)
    'Pong'
  end

  route do |r|
    r.get('ping') { pong }
  end
end
```

1. Include a plugin, after included Roda has a class level method `endpoint`
2. Use the `endpoint` to mark a specified method as a function that may handle a request. When a
   function will be invoked a key `x.rack.endpoint` with a value `pong` will be exported into Rack env.

<hr>

# Management Server Puma plugin

The `management_server` plugin provides monitoring and metrics on different HTTP port, it starts a separated
`Puma::Server` that serves requests.

The plugin exposes few endpoints
* `/ping` - a liveness probe, always return `HTTP 200 OK` when the server is running
* `/metrics` - metrics list from the current Prometheus registry
* `/gc-status` - print ruby GC statistics as JSON
* `/threads` - print running threads, names and backtraces as JSON

By default the server is running on `0.0.0.0:9990`, the default configuration values could be override in puma
configuration file.

```ruby
# config/puma.rb
plugin(:management_server)

# or override default configuration
plugin(:management_server)
management_server(host: '127.0.0.1', port: 9000, logger: Logger.new(IO::NULL))
```

#### Collected metrics

| Metrics | Type | Labels | Description |
|---------|------|--------|-------------|
| `puma_thread_pool_max_size` | gauge | - | The preconfigured maximum number of worker threads in the Puma server |
| `puma_thread_pool_size` | gauge | - | The number of spawned worker threads in the Puma server |
| `puma_thread_pool_active_size` | gauge | - | The number of worker threads that actively executing requests in the Puma server |
| `puma_thread_pool_queue_size` | gauge | - | The number of queued requests that waiting execution in the Puma server |
| `puma_server_socket_backlog_size` | gauge | `listener` | __Linux only__<br>The current size of the pending connection queue of the Puma listener | 
| `puma_server_socket_backlog_max_size` | gauge | `listener` | __Linux only__<br>The preconfigured maximum size of the pending connections queue of the Puma listener |

# License

The gem is available as open source under the terms of the [MIT
License][mit_license].

# Code of Conduct

Everyone interacting in the Bm::Instrumentations project's codebases,
issue trackers, chat rooms and mailing lists is expected to follow the
[code of conduct][code_of_conduit].

[mit_license]: https://opensource.org/licenses/MIT
[code_of_conduit]: https://github.com/bookmate/backend-commons/bm-instrumentations/blob/master/CODE_OF_CONDUCT.md

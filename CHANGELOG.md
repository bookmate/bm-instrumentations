# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Ability to use custom metric collectors

### Changed

- __Breaking__ The class `BM::Instrumentations::Aws::Collector` turned into gem private,
  the method `BM::Instrumentations::Aws.plugin` should be use to include the plugin
- __Breaking__ The class `BM::Instrumentations::Management::Server` turned into gem private,
  the method `BM::Instrumentations::Management.server` should be use to create a server
- __Breaking__ The middleware `BM::Instrumentations::Rack::Collector` renamed to 
  `BM::Instrumentations::Rack`

## [0.1.1] - 2021-05-14

### Added
- `BM::Instrumentations::Rack` rename `status` label into `status_code` and write `status` as cumulative value
  like `2xx`, `4xx`, `5xx`
- `BM::Instrumentations::Puma` exports the running Server version as `puma_server_version(version)` gauge

## [0.1.0] - 2021-05-13

### Added
- initial release

[unreleased]: https://github.com/bookmate/bm-instrumentations/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/bookmate/bm-instrumentations/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/bookmate/bm-instrumentations/releases/tag/v0.1.0

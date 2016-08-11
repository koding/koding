# Change Log
All notable changes to this project will be documented in this file.

## [3.0.5] - 2016-07-20
### Added
- README updates
- Update introduction blurb to include information regarding our forward path
- Update the v3 /mail/send example to include non-helper usage
- Update the generic v3 example to include non-fluent interface usage

## [3.0.4] - 2016-07-12
### Added
- Update docs, unit tests and examples to include Sender ID
### Fixed
- Missing example query params for the examples

## [3.0.3] - 2016-07-08
### Fixed
- [Can't disable subscription tracking #68](https://github.com/sendgrid/sendgrid-go/issues/68)

## [3.0.2] - 2016-07-07
### Added
- Tests now mocked automatically against [prism](https://stoplight.io/prism/)

## [3.0.1] - 2016-07-05
### Added
- Accept: application/json header per https://sendgrid.com/docs/API_Reference/Web_API_v3/How_To_Use_The_Web_API_v3/requests.html

### Updated
- Content based on our updated [Swagger/OAI doc](https://github.com/sendgrid/sendgrid-oai)

## [3.0.0] - 2016-06-14
### Added
- Breaking change to support the v3 Web API
- New HTTP client
- v3 Mail Send helper

## [2.0.0] - 2015-05-02
### Changed
- Fixed a nasty bug with orphaned connections but drops support for Go versions < 1.3. Thanks [trinchan](https://github.com/sendgrid/sendgrid-go/pull/24)

## [1.2.0] - 2015-04-27
### Added
- Support for API keys


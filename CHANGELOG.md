# Changelog

All notable changes to AsyncObservable will be documented in this file.

## [0.3.0] - 2025-03-08

### Changed
- I changed the API because I like to use the word "value" in other parts of my code and I ended up using "value.value" and it made me sad.
  - value -> raw
  - valueObservable -> observable
  - valueStream -> stream

## [0.2.1] - 2025-03-07

### Added
- Added AsyncObservableReadOnly protocol for read-only access to AsyncObservable properties

## [0.2.0] - 2025-03-07

### Fixed
- It now compiles on Linux.

## [0.0.1] - Initial Release

### Added
- Initial commit
- Basic project structure

[Unreleased]: https://github.com/username/AsyncObservable/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/username/AsyncObservable/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/username/AsyncObservable/compare/v0.0.1...v0.2.0
[0.0.1]: https://github.com/username/AsyncObservable/releases/tag/v0.0.1 
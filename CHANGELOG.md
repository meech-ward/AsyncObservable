# Changelog

All notable changes to AsyncObservable will be documented in this file.

## [0.4.1] - 2025-03-09

### Added
- Remove continuation manually if terminated by not being assigned to a variable

## [0.4.0] - 2025-03-09

### Added
- Added AsyncObservableUnwrapped.
```swift
let value: AsyncObservableUnwrapped<Data> = .init(nil) 
value.current // Data?
value.observable // Data?
value.stream // Data
```
- Added swift docc

### Removed
- Removed unwrappedStream() method from AsyncObservable.
- 
### Changed
- I changed the API again because raw feels wrong. Now its `property.current`

## [0.3.2] - 2025-03-08

### Fixed
- made unwrappedStream public

## [0.3.1] - 2025-03-08

### Added
- Added unwrappedStream() method to AsyncObservable that allows you to read a stream of only non-nil values when the type is Optional.

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
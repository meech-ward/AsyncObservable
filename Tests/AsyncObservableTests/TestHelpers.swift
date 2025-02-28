import Foundation
import Testing
@testable import AsyncObservable

// Common helper functions for AsyncObservable tests
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
func ensureValue<T: Equatable>(_ expectedValue: T, asyncObservable: AsyncObservable<T>) async {
  #expect(asyncObservable.value == expectedValue)
  await #expect(asyncObservable.valueObservable == expectedValue)
  for await actualValue in asyncObservable.valueStream {
    #expect(actualValue == expectedValue)
    break
  }
} 
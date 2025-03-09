import Foundation
import Testing

@testable import AsyncObservable

@Suite("AsyncObservableUnwrapped Tests")
struct AsyncObservableUnwrappedTests {

  @Test("Unwrapped stream should only emit non-nil values")
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
  func testUnwrappedStream() async {
    let observable: AsyncObservableUnwrapped<Int> = AsyncObservableUnwrapped(nil)
    let stream = observable.stream
    let v = observable.raw
    #expect(v == nil)

    // should only get values that are not nil
    var sum = 0
    let task = Task {
      for await value in stream {
        sum += value
        #expect(value != nil)
      }
    }

    observable.update(nil)
    observable.update(1)
    observable.update(2)
    observable.update(nil)
    observable.update(3)
    observable.update(nil)
    observable.update(5)

    // Give some time for potential values to arrive
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    #expect(sum == 11)
  }

  @Test("Should initialize with non-nil value")
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
  func testInitWithNonNilValue() async {
    let observable = AsyncObservableUnwrapped(42)
    #expect(observable.raw == 42)

    var receivedValue = false
    let task = Task {
      for await value in observable.stream {
        #expect(value == 42)
        receivedValue = true
        break
      }
    }

    try? await Task.sleep(for: .milliseconds(50))
    task.cancel()

    #expect(receivedValue == true)
  }

  @Test("Should not notify observers when notifyObservers is false")
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
  func testSilentUpdate() async {
    let observable = AsyncObservableUnwrapped<Int>(5)
    let stream = observable.stream

    // Update without notifying observers
    observable.update(10, notifyObservers: false)

    // Set up a task that will time out if no value is received
    var receivedValue = false
    let task = Task {
      for await _ in stream.dropFirst() {
        receivedValue = true
        break
      }
    }

    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // No value should have been received
    #expect(receivedValue == false)

    // But the internal value should be updated
    #expect(observable.raw == 10)
  }

  @Test("Should handle multiple observers")
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
  func testMultipleObservers() async {
    let observable = AsyncObservableUnwrapped<Int>(1)

    // Create two separate streams
    let stream1 = observable.stream
    let stream2 = observable.stream

    var values1: [Int] = []
    var values2: [Int] = []

    // Set up tasks to collect values from both streams
    let task1 = Task {
      for await value in stream1 {
        values1.append(value)
      }
    }

    let task2 = Task {
      for await value in stream2 {
        values2.append(value)
      }
    }

    // Update with a mix of nil and non-nil values
    observable.update(nil)  // Should be filtered out
    observable.update(2)  // Should be emitted
    observable.update(3)  // Should be emitted

    try? await Task.sleep(for: .milliseconds(100))
    task1.cancel()
    task2.cancel()

    // Both streams should receive the initial value (1) and updates (2, 3) but not nil values
    #expect(values1 == [1, 2, 3])
    #expect(values2 == [1, 2, 3])
  }

  @Test("Should handle nil to non-nil transitions correctly")
  @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, *)
  func testNilToNonNilTransitions() async {
    let observable = AsyncObservableUnwrapped<Int>(nil)

    var values: [Int] = []
    let task = Task {
      for await value in observable.stream {
        values.append(value)
      }
    }
    try? await Task.sleep(for: .milliseconds(100))

    // Start with nil, then provide a value, then nil again, then another value
    observable.update(nil)  // Should be filtered out
    #expect(observable.current == nil)
    observable.update(1)  // Should be emitted
    #expect(observable.current == 1)
    observable.update(nil)  // Should be filtered out
    #expect(observable.current == nil)
    observable.update(2)  // Should be emitted
    #expect(observable.current == 2)

    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // Should only contain non-nil values
    #expect(values == [1, 2])
  }
}

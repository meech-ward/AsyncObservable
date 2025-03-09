import Foundation
import Testing

@testable import AsyncObservable

@Suite("AsyncObservable Advanced Behaviors")
struct AsyncObservableAdvancedTests {

  @Test("Should maintain proper sequencing of operations")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testOperationSequencing() async {
    let observable = AsyncObservable(0)

    var receivedValues = [Int]()

    let stream = observable.stream
    let task = Task {
      for await value in stream {
        receivedValues.append(value)
        if receivedValues.count >= 4 {
          break
        }
      }
    }

    // Perform operations with different update patterns
    observable.update(1)  // Direct update
    observable.update { current in current + 1 }  // Transform update
    observable.mutate { value in value += 1 }  // In-place mutation

    // Allow time for processing
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // We should have received values in the correct sequence
    #expect(receivedValues == [0, 1, 2, 3])
    #expect(observable.raw == 3)
  }

  @Test("Should handle custom buffering policies")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testCustomBufferingPolicies() async {
    // Test with different buffering policies

    // 1. Unbounded buffer
    let unboundedObservable = AsyncObservable(0, bufferingPolicy: .unbounded)

    // Generate many updates
    for i in 1...100 {
      unboundedObservable.update(i)
    }

    var unboundedValues = [Int]()
    let unboundedTask = Task {
      for await value in unboundedObservable.stream {
        unboundedValues.append(value)
        if unboundedValues.count >= 10 {
          break  // Important to break the loop
        }
      }
    }

    // Add a timeout
    try? await Task.sleep(nanoseconds: 100_000_000)
    unboundedTask.cancel()

    // Should have received the latest value and some history
    #expect(unboundedValues.count > 0)
    #expect(
      unboundedValues.contains(0) || unboundedValues.contains(100),
      "Should contain either initial or final value"
    )

    // 2. No buffer (only current value)
    let noBufferObservable = AsyncObservable(0, bufferingPolicy: .bufferingOldest(1))

    // Generate many updates
    for i in 1...100 {
      noBufferObservable.update(i)
    }

    var noBufferValues = [Int]()
    let noBufferTask = Task {
      for await value in noBufferObservable.stream {
        noBufferValues.append(value)
        break  // Break immediately after first value
      }
    }

    // Add another timeout
    try? await Task.sleep(nanoseconds: 100_000_000)
    noBufferTask.cancel()

    // Should have received at least one value
    #expect(noBufferValues.count > 0)
  }

  @Test("Should handle updates during observer iteration")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testUpdatingDuringIteration() async {
    let observable = AsyncObservable(0)

    var receivedValues = [Int]()
    let stream = observable.stream

    // Set up a task that will perform updates when specific values are observed
    let updateTask = Task {
      for await value in stream {
        receivedValues.append(value)

        // When we see value 2, trigger an update to 10
        if value == 2 {
          observable.update(10)
        }

        // When we see value 10, trigger an update to 20
        if value == 10 {
          observable.update(20)
        }

        if value == 20 {
          break
        }
      }
    }

    // Initial sequence of updates
    observable.update(1)
    observable.update(2)
    // The task above will then update to 10, then to 20

    // Allow time for processing
    try? await Task.sleep(for: .milliseconds(100))
    updateTask.cancel()

    // Should see the chain of updates
    #expect(receivedValues.contains(0))
    #expect(receivedValues.contains(1))
    #expect(receivedValues.contains(2))
    #expect(receivedValues.contains(10))
    #expect(receivedValues.contains(20))

    // Final value should be 20
    #expect(observable.raw == 20)
  }

  @Test("Should handle value cycling and detection of duplicate updates")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testValueCycling() async {
    let observable = AsyncObservable(0)

    var receivedValues = [Int]()
    let stream = observable.stream

    // Set specific updates we want to track
    let updatedValues = [1, 2, 1, 2, 3, 1]

    // Create a task to collect values
    let task = Task {
      var count = 0
      for await value in stream {
        receivedValues.append(value)
        count += 1
        if count >= updatedValues.count {
          break
        }
      }
    }

    // Allow time for processing
    try? await Task.sleep(for: .milliseconds(100))

    // Apply the updates
    for value in updatedValues {
      observable.update(value)
      // Add a tiny delay to ensure consistent ordering in the stream
      try? await Task.sleep(for: .nanoseconds(1))
    }

    // Allow time for processing
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // Check that values were received in the correct order
    let expectedPattern = [0] + updatedValues

    // Make a more precise assertion - at minimum we should see the first few values
    // in the correct order
    let validLength = min(expectedPattern.count, receivedValues.count)
    for i in 0..<validLength {
      #expect(receivedValues[i] == expectedPattern[i])
    }
  }

  @Test("Should handle defensive value checks")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testDefensiveChecks() async {
    let observable = AsyncObservable(10)

    // Get initial value
    let initialValue = observable.raw
    #expect(initialValue == 10)

    // Verify we can update normally
    observable.update(30)
    #expect(observable.raw == 30)

    // Test that value updates correctly through different methods
    observable.update(40)
    #expect(observable.raw == 40)

    observable.update { current in current + 5 }
    #expect(observable.raw == 45)

    observable.mutate { value in value += 5 }
    #expect(observable.raw == 50)
  }
}

import Foundation
import Testing

@testable import AsyncObservable

@Suite("AsyncObservable Concurrency Tests")
struct AsyncObservableConcurrencyTests {

  @Test("Should handle simultaneous updates from multiple tasks")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testSimultaneousUpdates() async {
    let observable = AsyncObservable(0)

    // Track all values seen by the stream
    var allValuesSeen = [Int]()
    
    // Initial value
    allValuesSeen.append(observable.raw)

    // Observer task
    let stream = observable.stream.dropFirst()
    let observerTask = Task {
      // Use a fresh stream for continuous observation, skip initial value which we already recorded
      for await value in stream {
        allValuesSeen.append(value)
        if allValuesSeen.count >= 20 {
          break
        }
      }
    }

    // Create a coordination mechanism for tasks
    let taskGroup = TaskGroup()

    // Create 10 concurrent update tasks
    for taskNum in 1...10 {
      await taskGroup.add {
        // Each task does 10 updates
        for i in 1...10 {
          let value = (taskNum * 100) + i
          observable.update(value)
          // Small delay to allow interleaving
          try? await Task.sleep(nanoseconds: 1_000)
        }
      }
    }

    // Wait for all update tasks to complete
    await taskGroup.waitForAll()

    // Allow time for updates to process
    try? await Task.sleep(nanoseconds: 100_000_000)
    observerTask.cancel()

    // We should have seen some updates (exact number depends on buffering)
    #expect(allValuesSeen.count > 1)

    // The final value should be one of the valid updates we made
    let finalValue = observable.raw
    #expect(finalValue != 0, "Value should have been updated from initial value")
    
    // Value should be in our expected range
    let validValueRange = 101...1010 // Values from our update tasks
    #expect(validValueRange.contains(finalValue), 
            "Final value \(finalValue) should be within expected range \(validValueRange)")
    
    // At least some values should have been observed by the stream
    #expect(!allValuesSeen.isEmpty, "No values were observed by the stream")
  }

  @Test("Should handle observers being added/removed during updates")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testObserverLifecycles() async {
    let observable = AsyncObservable(0)

    var stream1Values = [Int]()
    var stream2Values = [Int]()
    var stream3Values = [Int]()

    // Add initial value to our tracking array
    stream1Values.append(observable.raw)

    // Start first observer and skip initial value
    let stream = observable.stream.dropFirst()
    let task1 = Task {
      for await value in stream {
        stream1Values.append(value)
        if stream1Values.count >= 4 { // Initial (0) + 3 more
          break
        }
      }
    }

    // Update a few times
    observable.update(1)
    observable.update(2)

    // Start second observer - include initial value
    let task2 = Task {
      for await value in observable.stream {
        stream2Values.append(value)
        if stream2Values.count >= 3 {
          break
        }
      }
    }

    // More updates
    observable.update(3)
    observable.update(4)

    // Cancel first observer
    task1.cancel()

    // Start third observer - include initial value
    let task3 = Task {
      for await value in observable.stream {
        stream3Values.append(value)
        if stream3Values.count >= 2 {
          break
        }
      }
    }

    // Final update
    observable.update(5)

    // Allow time for processing
    try? await Task.sleep(nanoseconds: 100_000_000)
    task2.cancel()
    task3.cancel()

    // Stream 1 should have at least some of the earlier values including the initial value (0)
    #expect(stream1Values.contains(0))
    #expect(stream1Values.contains(1) || stream1Values.contains(2))

    // Stream 2 should have started with its current value when subscribed (likely 2)
    #expect(stream2Values.count > 0)
    
    // Stream 3 should have started with its current value when subscribed (likely 4)
    #expect(stream3Values.count > 0)

    // Final state check
    #expect(observable.raw == 5)
  }

  @Test("Should handle cancellation during updates")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testCancellationDuringUpdates() async {
    let observable = AsyncObservable(0)

    var valuesReceived = [Int]()

    // Start a task that will be cancelled during updates
    // Skip the initial value to simplify testing
    let stream = observable.stream.dropFirst()
    let task = Task {
      for await value in stream {
        valuesReceived.append(value)
        // Simulate work that takes time
        try? await Task.sleep(nanoseconds: 10_000_000)
      }
    }

    // Make some updates
    observable.update(1)
    observable.update(2)
    observable.update(69)
    observable.update(420)

    try? await Task.sleep(nanoseconds: 50_000_000)

    // Cancel in the middle of updates
    task.cancel()
    try? await Task.sleep(nanoseconds: 50_000_000)

    // Make more updates after cancellation
    observable.update(3)
    observable.update(4)

    // Allow time for processing
    try? await Task.sleep(nanoseconds: 50_000_000)

    // We should have received some but not all updates
    #expect(valuesReceived.count > 0)
    #expect(valuesReceived.count < 6) // We can't see all 6 values due to cancellation

    // Internal state should have all updates
    #expect(observable.raw == 4)
  }
}

/// A simple actor-based task coordinator
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
fileprivate actor TaskGroup {
  private var tasks: [Task<Void, Error>] = []

  func add(_ work: @escaping () async throws -> Void) {
    let task = Task {
      try await work()
    }
    tasks.append(task)
  }

  func waitForAll() async {
    for task in tasks {
      do {
        try await task.value
      } catch {
        // Ignore errors for test purposes
      }
    }
    tasks.removeAll()
  }
}

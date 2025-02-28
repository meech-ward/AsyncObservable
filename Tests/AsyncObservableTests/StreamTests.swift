import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable Stream Tests")
struct AsyncObservableStreamTests {

  @Test("Should provide updates via async stream")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testAsyncStream() async {
    let observable = AsyncObservable(0)

    var receivedValues: [Int] = []
    let valueStream = observable.valueStream

    // Consume initial value first
    // Now set up a task to capture the next values
    let task = Task {
      var count = 0
      for await value in valueStream {
        receivedValues.append(value)
        count += 1
        if count >= 3 {
          break
        }
      }
    }

    // Make updates that should be observed
    observable.update(1)
    observable.update(2)

    // Allow time for the stream to process values
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    #expect(receivedValues == [0, 1, 2])
  }
  
  @Test("Should handle multiple observers")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testMultipleObservers() async {
    let observable = AsyncObservable(0)

    // Create two separate streams
    let stream1 = observable.valueStream
    let stream2 = observable.valueStream
    
    // Consume initial values first
    var values1: [Int] = []
    var values2: [Int] = []

    // Set up tasks to collect subsequent values from both streams
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

    // Make an update that both streams should receive
    observable.update(1)

    // Allow time for both streams to process values
    try? await Task.sleep(for: .milliseconds(100))
    task1.cancel()
    task2.cancel()

    // Both streams should receive initial value (0) and the update (1)
    #expect(values1 == [0, 1])
    #expect(values2 == [0, 1])
  }

  @Test("Should respect buffering policy")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testBufferingPolicy() async {
    // Create observable with buffer size of 2
    let observable = AsyncObservable(0, bufferingPolicy: .bufferingNewest(2))

    // Make multiple updates before starting to observe
    observable.update(1)
    observable.update(2)
    observable.update(3)
    observable.update(4)

    // Now start observing - we should get the current value (4) and possibly some buffered values
    var receivedValues: [Int] = []
    
    // Create a task with a timeout to avoid hanging
    let task = Task {
      for await value in observable.valueStream {
        receivedValues.append(value)
        if receivedValues.count >= 3 {
          break
        }
      }
    }
    
    // Add a timeout to ensure the test doesn't hang if the stream doesn't yield enough values
    try? await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()

    // Should have received some values - at minimum the current value
    #expect(receivedValues.count > 0)
    #expect(receivedValues.contains(4), "Should contain the latest value")
  }
  
  @Test("Should not update observers when notifyObservers is false")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testSilentUpdate() async {
    let observable = AsyncObservable(10)
    let valueStream = observable.valueStream

    // Consume initial value
    for await value in valueStream {
      #expect(value == 10)
      break
    }

    // Update without notifying observers
    observable.update(20, notifyObservers: false)

    // Set up a task that will time out if no value is received
    var receivedValue = false
    let task = Task {
      for await _ in valueStream {
        receivedValue = true
        break
      }
    }

    // Give some time for potential values to arrive
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()

    // No value should have been received
    #expect(receivedValue == false)
    
    // But the internal value should be updated
    #expect(observable.value == 20)
    await #expect(observable.valueObservable == 20)
  }
} 
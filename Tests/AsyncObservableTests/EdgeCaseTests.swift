import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable Edge Cases")
struct AsyncObservableEdgeCasesTests {
  
  @Test("Should handle nil optional values")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testNilOptionalValues() async {
    let observable = AsyncObservable<Int?>(42)
    
    // Update to nil
    observable.update(nil)
    
    #expect(observable.raw == nil)
    await #expect(observable.observable == nil)
    
    // Update from nil back to value
    observable.update(100)
    
    #expect(observable.raw == 100)
    await #expect(observable.observable == 100)
  }
  
  @Test("Should handle empty collections")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testEmptyCollections() async {
    // Start with non-empty collection
    let observable = AsyncObservable(["a", "b", "c"])
    
    // Update to empty
    observable.update([])
    
    #expect(observable.raw.isEmpty)
    await #expect(observable.observable.isEmpty)
    
    // Test with stream
    let stream = observable.stream
    
    for await value in stream {
      #expect(value.isEmpty)
      break
    }
  }
  
  @Test("Should handle moderately large values")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testLargeValues() async {
    // Create a moderate array (10,000 elements is enough to test the concept)
    let largeArray = Array(repeating: "test", count: 10_000)
    let observable = AsyncObservable(largeArray)
    
    #expect(observable.raw.count == 10_000)
    
    // Update with another array (20,000 elements)
    let largerArray = Array(repeating: "test", count: 20_000)
    observable.update(largerArray)
    
    #expect(observable.raw.count == 20_000)
    await #expect(observable.observable.count == 20_000)
  }
  
  @Test("Should handle frequent rapid updates")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testRapidUpdates() async {
    let observable = AsyncObservable(0)
    let stream = observable.stream
    
    // Perform 1000 rapid updates
    var lastSeen = -1
    let task = Task {
      var count = 0
      for await value in stream {
        lastSeen = value
        count += 1
        if count >= 10 { // Only wait for 10 values to avoid test taking too long
          break
        }
      }
    }
    
    // Rapid updates
    for i in 1...1000 {
      observable.update(i)
    }
    
    // Allow time for some updates to be processed
    try? await Task.sleep(for: .milliseconds(100))
    task.cancel()
    
    // We should have seen at least the last value
    #expect(lastSeen > 1)
    #expect(observable.raw == 1000)
  }
  
  @Test("Should handle deeply nested structures")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testDeepNestedStructures() async {
    // Create a deeply nested structure
    struct NestedStruct: Sendable, Equatable {
      var name: String
      var children: [NestedStruct]
    }
    
    // Create a 5-level deep structure
    let level5 = NestedStruct(name: "Level 5", children: [])
    let level4 = NestedStruct(name: "Level 4", children: [level5])
    let level3 = NestedStruct(name: "Level 3", children: [level4])
    let level2 = NestedStruct(name: "Level 2", children: [level3])
    let level1 = NestedStruct(name: "Level 1", children: [level2])
    
    let observable = AsyncObservable(level1)
    
    // Mutate a deeply nested value
    observable.mutate { root in
      root.children[0].children[0].children[0].children[0].name = "Updated Level 5"
    }
    
    // Check the deep update worked
    #expect(observable.raw.children[0].children[0].children[0].children[0].name == "Updated Level 5")
  }
} 
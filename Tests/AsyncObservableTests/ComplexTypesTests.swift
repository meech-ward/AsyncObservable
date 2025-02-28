import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable Complex Types Tests")
struct AsyncObservableComplexTypesTests {
  
  @Test("Should handle complex types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testComplexTypes() async {
    struct User: Sendable, Equatable {
      var name: String
      var age: Int
    }

    let initialUser = User(name: "John", age: 30)
    let observable = await AsyncObservable(initialUser)

    let valueStream = observable.valueStream
    // Consume initial value
    for await value in valueStream {
      #expect(value == initialUser)
      break
    }
    
    observable.mutate { user in
      user.name = "Jane"
      user.age = 25
    }

    let expectedUser = User(name: "Jane", age: 25)
    
    // Check updated value in stream
    for await value in valueStream {
      #expect(value == expectedUser)
      break
    }
    
    // Check other interfaces
    #expect(observable.value == expectedUser)
    await #expect(observable.valueObservable == expectedUser)
  }
  
  @Test("Should handle reference types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testReferenceTypes() async {
    // Using a @unchecked Sendable to avoid the warning about mutable properties
    // This simulates a real-world scenario where reference types need thread safety guarantees
    final class Counter: @unchecked Sendable, Equatable {
      var count: Int
      
      init(count: Int) {
        self.count = count
      }
      
      static func == (lhs: Counter, rhs: Counter) -> Bool {
        lhs.count == rhs.count
      }
    }
    
    let initialCounter = Counter(count: 0)
    let observable = await AsyncObservable(initialCounter)
    
    // Change the referenced object state
    observable.mutate { counter in
      counter.count = 10
    }
    
    // The same instance with updated state should be observable
    #expect(observable.value.count == 10)
    
    // Reference equality should be maintained
    #expect(observable.value === initialCounter)
    
    // Create a new instance with the same value
    let newCounter = Counter(count: 10)
    
    // Update to a new instance
    observable.update(newCounter)
    
    // Value equality should match
    #expect(observable.value == newCounter)
    
    // But reference equality should differ
    #expect(observable.value !== initialCounter)
    #expect(observable.value === newCounter)
  }
} 
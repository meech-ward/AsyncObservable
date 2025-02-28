import Foundation
import Testing
@testable import AsyncObservable

/// Tests that focus on ensuring the API works correctly with different kinds of Swift types
@Suite("AsyncObservable Compilation Tests")
struct AsyncObservableCompilationTests {
  
  /// Tests that AsyncObservable works with Swift standard library types
  @Test("Should compile with standard Swift types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testStandardTypes() async {
    // Test with String
    let stringObservable = AsyncObservable("test")
    #expect(stringObservable.value == "test")
    
    // Test with Bool
    let boolObservable = AsyncObservable(true)
    #expect(boolObservable.value)
    
    // Test with Double
    let doubleObservable = AsyncObservable(3.14)
    #expect(doubleObservable.value == 3.14)
    #expect(abs(doubleObservable.value - 3.14) < 0.00001)
    
    // Test with Date
    let now = Date()
    let dateObservable = AsyncObservable(now)
    #expect(dateObservable.value == now)
    
    // Test with UUID
    let uuid = UUID()
    let uuidObservable = AsyncObservable(uuid)
    #expect(uuidObservable.value == uuid)
    
    // Test with URL
    let url = URL(string: "https://example.com")!
    let urlObservable = AsyncObservable(url)
    #expect(urlObservable.value == url)
  }
  
  /// Tests that AsyncObservable works with custom types that implement required protocols
  @Test("Should compile with custom types implementing Sendable and Equatable")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testCustomTypes() async {
    // Custom value type
    struct Point: Sendable, Equatable {
      var x: Double
      var y: Double
    }
    
    let pointObservable = AsyncObservable(Point(x: 1.0, y: 2.0))
    #expect(pointObservable.value.x == 1.0)
    #expect(pointObservable.value.y == 2.0)
    
    // Custom class type
    final class Person: Sendable, Equatable {
      let name: String
      
      init(name: String) {
        self.name = name
      }
      
      static func == (lhs: Person, rhs: Person) -> Bool {
        return lhs.name == rhs.name
      }
    }
    
    let personObservable = AsyncObservable(Person(name: "Alice"))
    #expect(personObservable.value.name == "Alice")
  }
  
  /// Tests that AsyncObservable works with collection types
  @Test("Should compile with collection types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testCollectionTypes() async {
    // Test with Array
    let arrayObservable = AsyncObservable([1, 2, 3])
    #expect(arrayObservable.value.count == 3)
    
    // Test with Dictionary
    let dictObservable = AsyncObservable(["a": 1, "b": 2])
    #expect(dictObservable.value.count == 2)
    
    // Test with Set
    let setObservable = AsyncObservable(Set([1, 2, 3]))
    #expect(setObservable.value.count == 3)
    
    // Test with nested collections
    let nestedObservable = AsyncObservable([[1, 2], [3, 4]])
    #expect(nestedObservable.value.count == 2)
    #expect(nestedObservable.value[0].count == 2)
  }
  
  /// Tests that AsyncObservable works with optional types
  @Test("Should compile with optional types")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testOptionalTypes() async {
    // Test with optional Int
    let optionalObservable = AsyncObservable<Int?>(42)
    #expect(optionalObservable.value == 42)
    
    optionalObservable.update(nil)
    #expect(optionalObservable.value == nil)
    
    // Test with optional String
    let stringOptionalObservable = AsyncObservable<String?>(nil)
    #expect(stringOptionalObservable.value == nil)
    
    stringOptionalObservable.update("test")
    #expect(stringOptionalObservable.value == "test")
  }
} 
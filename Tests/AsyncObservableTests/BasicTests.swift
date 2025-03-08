import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable Basic Tests")
struct AsyncObservableBasicTests {
  
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  private func ensureValue<T: Equatable>(_ value: T, asyncObservable: AsyncObservable<T>) async {
    #expect(asyncObservable.raw == value)
    await #expect(asyncObservable.observable == value)
    for await value in asyncObservable.stream {
      #expect(value == value)
      break
    }
  }

  @Test("Should initialize with correct value")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testInitialization() async {
    let initialValue = 42
    let observable = AsyncObservable(initialValue)

    await ensureValue(initialValue, asyncObservable: observable)
  }

  @Test("Should update value directly")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testDirectUpdate() async {
    let observable = AsyncObservable(0)
    let newValue = 100

    let stream = observable.stream
    observable.update(newValue)
    await #expect(stream.first { _ in true } == 0)
    await #expect(stream.first { _ in true } == newValue)

    await ensureValue(newValue, asyncObservable: observable)
  }

  @Test("Should update value with transform")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testTransformUpdate() async {
    let observable = AsyncObservable(10)

    let stream = observable.stream
    observable.update { currentValue in
      return currentValue * 2
    }
    await #expect(stream.first { _ in true } == 10)
    await #expect(stream.first { _ in true } == 20)
    await ensureValue(20, asyncObservable: observable)
  }

  @Test("Should mutate value in place")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testMutateValue() async {
    let observable = AsyncObservable([1, 2, 3])

    let stream = observable.stream
    observable.mutate { value in
      value.append(4)
    }
    await #expect(stream.first { _ in true } == [1, 2, 3])
    await #expect(stream.first { _ in true } == [1, 2, 3, 4])

    #expect(observable.raw == [1, 2, 3, 4])
    await #expect(observable.observable == [1, 2, 3, 4])
  }
} 
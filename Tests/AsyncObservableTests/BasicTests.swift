import Foundation
import Testing
@testable import AsyncObservable

@Suite("AsyncObservable Basic Tests")
struct AsyncObservableBasicTests {
  
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  private func ensureValue<T: Equatable>(_ value: T, asyncObservable: AsyncObservable<T>) async {
    #expect(asyncObservable.value == value)
    await #expect(asyncObservable.valueObservable == value)
    for await value in asyncObservable.valueStream {
      #expect(value == value)
      break
    }
  }

  @Test("Should initialize with correct value")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testInitialization() async {
    let initialValue = 42
    let observable = await AsyncObservable(initialValue)

    await ensureValue(initialValue, asyncObservable: observable)
  }

  @Test("Should update value directly")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testDirectUpdate() async {
    let observable = await AsyncObservable(0)
    let newValue = 100

    let valueStream = observable.valueStream
    observable.update(newValue)
    await #expect(valueStream.first { _ in true } == 0)
    await #expect(valueStream.first { _ in true } == newValue)

    await ensureValue(newValue, asyncObservable: observable)
  }

  @Test("Should update value with transform")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testTransformUpdate() async {
    let observable = await AsyncObservable(10)

    let valueStream = observable.valueStream
    observable.update { currentValue in
      return currentValue * 2
    }
    await #expect(valueStream.first { _ in true } == 10)
    await #expect(valueStream.first { _ in true } == 20)
    await ensureValue(20, asyncObservable: observable)
  }

  @Test("Should mutate value in place")
  @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
  func testMutateValue() async {
    let observable = await AsyncObservable([1, 2, 3])

    let valueStream = observable.valueStream
    observable.mutate { value in
      value.append(4)
    }
    await #expect(valueStream.first { _ in true } == [1, 2, 3])
    await #expect(valueStream.first { _ in true } == [1, 2, 3, 4])

    #expect(observable.value == [1, 2, 3, 4])
    await #expect(observable.valueObservable == [1, 2, 3, 4])
  }
} 
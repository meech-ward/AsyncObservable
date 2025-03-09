# Getting Started with AsyncObservable

``AsyncObservable`` is a lightweight library that provides observable state management with Swift Concurrency support. It bridges the gap between traditional property observation and modern async/await patterns by offering both `@Observable` compatibility and async streams.

## Installation

### Swift Package Manager

Add AsyncObservable to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/meech-ward/AsyncObservable.git", from: "0.4.0")
]
```

Then add it to your target's dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["AsyncObservable"]),
]
```

Or add it directly in Xcode via File → Add Packages...

### Import

Import `AsyncObservable` in your source files:

```swift
import AsyncObservable
```

## Basic Usage

Create an observable property with an initial value:

```swift
let counter = AsyncObservable(0)
```

### Reading Values

Read the current value:

```swift
print(counter.current) // 0 (uses AsyncObservable/current)
```

### Updating Values

Update the value directly:

```swift
counter.update(1) // Uses AsyncObservable/update(_:)
```

Or update using a transform function:

```swift
counter.update { $0 + 1 } // Uses AsyncObservable/update(_:)
```

For collection types, you can mutate them in place:

```swift
let values = AsyncObservable([1, 2, 3])
values.mutate { $0.append(4) } // Uses AsyncObservable/mutate(_:)
```

### Observing Changes

Observe using async streams:

```swift
Task {
    for await value in counter.stream { // Uses AsyncObservable/stream
        print("Counter changed to: \(value)")
    }
}
```

Use with SwiftUI via the `@Observable` macro compatibility with the ``AsyncObservableBase/observable`` property:

```swift
struct CounterView: View {
    let counter: AsyncObservable<Int>
    
    var body: some View {
        Text("Count: \(counter.observable)")
    }
}
```

## Next Steps

- Learn about the <doc:CoreConcepts>
- Explore <doc:StreamingValues>
- See <doc:UseCases> for real-world examples

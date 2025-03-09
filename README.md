# AsyncObservable

![Build and Test](https://github.com/meech-ward/AsyncObservable/actions/workflows/build.yml/badge.svg)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmeech-ward%2FAsyncObservable%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/meech-ward/AsyncObservable)

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmeech-ward%2FAsyncObservable%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/meech-ward/AsyncObservable)

## What is AsyncObservable?

AsyncObservable is a lightweight library that provides observable state management with Swift Concurrency support. It bridges the gap between traditional property observation and modern async/await patterns by offering both `@Observable` compatibility and `async` streams. This makes it perfect for sharing state across your app while maintaining thread safety and supporting the latest Swift features.

Let me know if the API should change, otherwise this API will get bumped to 1.0.0.

```swift
// values
asyncObservable.current
asyncObservable.stream
asyncObservable.observable

// updates
asyncObservable.update(2)
asyncObservable.update { $0 + 1 }
asyncObservable.mutate { $0.append(4) }
```

## Installation

### Swift Package Manager

Add AsyncObservable to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/meech-ward/AsyncObservable.git", from: "0.4.0")
]
```

Or add it directly in Xcode via File → Add Packages...

## Overview

AsyncObservable provides some of the features that Combine used to offer, but using Swift concurrency and @Observable instead. This makes it more compatible with modern Swift setups and works on any platform that supports Swift 6.

At its core, AsyncObservable offers a thread-safe property that can be observed using either async streams or @Observable, with these key capabilities:

- **Thread safety**: Access and update properties safely from any context
- **Async stream support**: Use modern Swift concurrency for reactive workflows
- **@Observable integration**: Perfect for SwiftUI and modern Swift apps
- **Cross-actor communication**: Share state across different actors
- **Optional unwrapping**: Stream only non-nil values with `unwrappedStream`

```swift
import AsyncObservable

actor Something {
  let someProperty = AsyncObservable("Hello, world!")

  func funcThatUpdatesProperty() async {
    await someProperty.update("Hello, world! 2")
  }
}

let something = Something()
something.someProperty.current // "Hello, world!"

for await value in something.someProperty.stream {
  print(value) // hello world (then whatever the property is updated to)
}


struct SomethingView: View {
  let something: Something // Note: someProperty should be marked with @MainActor for this to work as is
  var body: some View {
    Text(something.someProperty.observable) // hello world (then whatever the property is updated to)
  }
}
```

## Stream

The streams buffering policy defaults to `.unbounded`, so it will "gather" values as soon as you create it.

```swift
let someProperty = AsyncObservable(1)

let stream = someProperty.stream // already has 1
someProperty.update { $0 + 1 } // 2
someProperty.update { $0 + 1 } // 3
someProperty.update { $0 + 1 } // 4

for await value in stream {
  print(value) // 1, 2, 3, 4
}
```

Canceling the task that the stream is running in will cancel the stream. So you don't need to have manual `if Task.isCancelled` checks. But you can still check it if you want.

```swift
let someProperty = AsyncObservable(1)

let stream = someProperty.stream // already has 1
let task = Task {
  for await value in stream {
    print(value) // 1, 2, 3
  }
}


someProperty.update { $0 + 1 } // 2
someProperty.update { $0 + 1 } // 3
task.cancel()
someProperty.update { $0 + 1 } // 4
```

Streams are finalized as soon as you break out of the loop, so you can't reuse them. But you can create as many new ones as you like.

```swift
let someProperty = AsyncObservable(1)

let stream = someProperty.stream // already has 1
// only print first value
for await value in stream {
  print(value) // 1
  break
}

// don't do this ❌
// the stream is already finalized
for await value in stream {
}

// do this ✅
for await value in someProperty.stream {
AsyncObservable
}
```


## AsyncObservableUnwrapped

For a more streamlined approach when working exclusively with optional types, you can use `AsyncObservableUnwrapped` which automatically provides a stream of non-nil values:

```swift
let value = AsyncObservableUnwrapped<Data>(nil)

// Standard access to the optional value
value.current // Data?
value.observable // Data?

// The stream automatically filters out nil values
for await data in value.stream {
  print(data) // Only non-nil Data values
}
```

## Mutate

Sometimes you just want to mutate the original value instead of having to copy and return a new value. This still updates all the observers correctly and is safe.

```swift
let values = AsyncObservable([1, 2, 3])

values.mutate { $0.append(4) }
```

## Read Only

If you want to expose an AsyncObservable as a read only property, you can use the `AsyncObservableReadOnly` protocol externally.

```swift
class SomeClass {
  // .update is availble on the private property
  private let _someProperty = AsyncObservable("whatever")
  // but not on the public property, unless someone casts, but this should be enought of a deterrent
  var someProperty: AsyncObservableReadOnly<String> { _someProperty }
}
```

## Buffering Policy

The buffering policy defaults to `.unbounded`, but you can change it on init.

```swift
let someProperty = AsyncObservable("Hello, world!", bufferingPolicy: .bufferingNewest(1))
```

## DispatchQueue

You can pass a custom dispatch queue to the initializer, just make sure it's a serial queue. Don't change the queue unless you really need to.

```swift
let someProperty = AsyncObservable("Hello, world!", dispatchQueue: DispatchQueue(label: "SomeQueue"))
```

## UserDefaults

Use the `AsyncObservableUserDefaults` class to store values in UserDefaults. Works just the same as `AsyncObservable`, but automatically saves to UserDefaults and loads from there.

```swift
let someProperty = AsyncObservableUserDefaults("someKey", initialValue: "Hello, world!")
```

## Common Use Cases

### Network Request State Management

```swift
actor NetworkService {
    let requestState = AsyncObservable<RequestState>(.idle)
    
    func fetchData() async throws {
        await requestState.update(.loading)
        do {
            let data = try await performNetworkRequest()
            await requestState.update(.success(data))
        } catch {
            await requestState.update(.failure(error))
        }
    }
}

// In SwiftUI
struct LoadingView: View {
    let networkService: NetworkService
    
    var body: some View {
        VStack {
            switch networkService.requestState.observable {
            case .idle: Text("Tap to load")
            case .loading: ProgressView()
            case .success(let data): DataView(data: data)
            case .failure(let error): ErrorView(error: error)
            }
        }
        .onAppear {
            Task { try await networkService.fetchData() }
        }
    }
}
```

### Cross-Actor Communication

```swift
actor DataProcessor {
    let progress = AsyncObservable(0.0)
    
    func processItems(_ items: [Item]) async {
        for (index, item) in items.enumerated() {
            await process(item)
            await progress.update(Double(index + 1) / Double(items.count))
        }
    }
}

// Monitor progress from anywhere
Task {
    for await progress in dataProcessor.progress.stream {
        print("Progress: \(Int(progress * 100))%")
    }
}
```

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

AsyncObservable is available under the MIT license. See the LICENSE file for more info.

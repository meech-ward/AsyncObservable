# Streaming Values

Learn how to work with AsyncObservable's streaming capabilities.

## Overview

One of ``AsyncObservable``'s key features is its ability to provide an async stream of values. This allows you to observe value changes over time using Swift's modern concurrency system.

## Basic Streaming

Every ``AsyncObservable`` instance provides a ``AsyncObservable/stream`` property that returns a ``StreamOf`` instance for asynchronous iteration:

```swift
let counter = AsyncObservable(0)

Task {
    for await value in counter.stream {
        print("Counter: \(value)")
    }
}

// Somewhere else in your code
counter.update(1) // Prints "Counter: 1"
counter.update(2) // Prints "Counter: 2"
```

The stream immediately emits the current value when you start iterating, and then emits new values whenever the observable is updated.

## Stream Lifecycle

Streams are finalized as soon as you break out of the iteration loop, and cannot be reused:

```swift
let counter = AsyncObservable(0)
let stream = counter.stream

Task {
    for await value in stream {
        print(value) // Prints "0"
        break // Finalizes the stream
    }
    
    // ❌ Don't do this - the stream is already finalized
    for await value in stream {
        // This will never execute
    }
    
    // ✅ Do this instead - create a new stream
    for await value in counter.stream {
        // This works fine
    }
}
```

## Stream Cancellation

A stream will automatically stop when the task it's running in is cancelled:

```swift
let counter = AsyncObservable(0)
let task = Task {
    for await value in counter.stream {
        print(value) // Will only print values until the task is cancelled
    }
}

// Later, when you want to stop observing
task.cancel()
```

## Buffering Behavior

By default, streams use an `.unbounded` buffering policy, which means they will "collect" all values as they are emitted, even if you haven't started iterating yet:

```swift
let counter = AsyncObservable(0)
let stream = counter.stream // Already buffering the initial value (0)

counter.update(1) // Buffered
counter.update(2) // Buffered
counter.update(3) // Buffered

Task {
    for await value in stream {
        print(value) // Prints: 0, 1, 2, 3, ...
    }
}
```

You can control this behavior by specifying a different buffering policy:

```swift
// Only buffer the most recent value
let counter = AsyncObservable(0, bufferingPolicy: .bufferingNewest(1))
```
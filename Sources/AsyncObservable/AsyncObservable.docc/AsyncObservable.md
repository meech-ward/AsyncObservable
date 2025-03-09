# ``AsyncObservable``

A Swift package for observable state management with Swift Concurrency support.

## Overview

AsyncObservable provides a thread-safe property that can be observed using either async streams or @Observable, with key capabilities including thread safety, async stream support, @Observable integration, cross-actor communication, and optional unwrapping features.

```swift
let counter = AsyncObservable(0)

// Read the current value
print(counter.current) // 0

// Update the value
counter.update(42)

// Observe via async stream
Task {
    for await value in counter.stream {
        print("Counter changed to: \(value)")
    }
}

// Use with SwiftUI
Text("\(counter.observable)")
```

## Topics

### Getting Started

- <doc:GettingStarted>

### Core Concepts

- <doc:CoreConcepts>
- <doc:StreamingValues>

### Special Types

- <doc:UnwrappedValues>
- <doc:UserDefaults>

### Articles

- <doc:UseCases>

### Main API

- ``AsyncObservable/AsyncObservable``
- ``AsyncObservableBase``
- ``AsyncObservableReadOnly``
- ``AsyncObservableUnwrapped``
- ``StreamOf``
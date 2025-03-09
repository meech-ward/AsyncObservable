# Core Concepts

Learn about the fundamental concepts in AsyncObservable.

## Overview

``AsyncObservable`` is built around a few core concepts that make it powerful and flexible for managing observable state in Swift applications. Understanding these concepts will help you leverage the library effectively.

## Thread Safety

Every ``AsyncObservable`` instance is internally synchronized, ensuring thread-safe access to the underlying value from any context, including different actors or dispatch queues.

```swift
actor DataManager {
    let state = AsyncObservable(State.idle)
    
    func process() async {
        await state.update(.processing) // Safe to call from within actor
    }
}

// Safe to access from outside the actor
Task {
    for await state in dataManager.state.stream {
        // Handle state changes
    }
}
```

## Observable Property

``AsyncObservable`` integrates with SwiftUI through the `@Observable` macro compatibility via the ``AsyncObservableBase/observable`` property, providing a reactive property that updates your UI whenever the value changes.

```swift
struct UserProfileView: View {
    let profile: AsyncObservable<UserProfile>
    
    var body: some View {
        VStack {
            Text(profile.observable.name)
            Text(profile.observable.email)
        }
    }
}
```

## Read-Only Access

When you want to expose an ``AsyncObservable`` for reading but not writing, use the ``AsyncObservableReadOnly`` protocol:

```swift
class UserManager {
    // Private mutable property
    private let _currentUser = AsyncObservable<User?>(nil)
    
    // Public read-only property
    var currentUser: AsyncObservableReadOnly<User?> { _currentUser }
    
    func login(user: User) {
        _currentUser.update(user)
    }
}
```

## Buffering Policy

You can control how values are buffered in the async stream with the `bufferingPolicy` parameter:

```swift
// Default: Unbounded - keeps all values
let fullHistory = AsyncObservable(0)

// Only buffer the most recent value
let latestOnly = AsyncObservable(0, bufferingPolicy: .bufferingNewest(1))
```

## Custom Dispatch Queue

AsyncObservable uses a dispatch queue for synchronization. By default, it creates its own serial queue, but you can provide a custom one:

```swift
let customQueue = DispatchQueue(label: "com.example.asyncobservable")
let observable = AsyncObservable(0, dispatchQueue: customQueue)
```
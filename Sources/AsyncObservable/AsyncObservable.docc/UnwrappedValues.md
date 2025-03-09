# Working with Optional Values

Learn how to work with optional values and unwrapped streams in AsyncObservable.

## Overview

``AsyncObservable`` provides specialized support for working with optional values, allowing you to stream only non-nil values when desired.


## AsyncObservableUnwrapped

For a more streamlined approach when working exclusively with optional types, you can use ``AsyncObservableUnwrapped``:

```swift
let userData = AsyncObservableUnwrapped<User>(nil)

// Access to the optional value
userData.current // nil
userData.observable // nil (SwiftUI compatible property)

// The stream automatically filters out nil values
Task {
    for await user in userData.stream {
        // Here, user is of type User (not User?), so no unwrapping needed
        print("User logged in: \(user.name)")
    }
}

// Later, update with an actual user
userData.update(User(name: "John"))
// The stream above will emit this user

// Clear the value
userData.update(nil)
// The stream won't emit for this update
```

## Use Cases

Unwrapped streams are particularly useful for:

- Network requests that may return nil or fail
- User authentication state where you only want to react to successful logins
- Resource loading where you want to process a resource only when it's available
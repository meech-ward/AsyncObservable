# Using UserDefaults with AsyncObservable

Learn how to use AsyncObservableUserDefaults to persist observable values.

## Overview

AsyncObservableUserDefaults provides a seamless integration between AsyncObservable and UserDefaults, allowing you to create observable properties that automatically persist their values.

## Basic Usage

First, import the module:

```swift
import AsyncObservableUserDefaults
```

Create a persisted observable with a key and initial value:

```swift
let settings = AsyncObservableUserDefaults("app.settings", initialValue: AppSettings.default)
```

This works just like a regular AsyncObservable, but it automatically saves values to UserDefaults whenever they change.

## Supported Types

AsyncObservableUserDefaults can store any type that conforms to `Codable`:

- Basic types: String, Int, Double, Bool
- Collections: Array, Dictionary, Set (of Codable types)
- Custom types that conform to Codable

```swift
struct UserPreferences: Codable {
    var darkMode: Bool
    var fontSize: Int
    var accentColor: String
}

let preferences = AsyncObservableUserDefaults(
    "user.preferences", 
    initialValue: UserPreferences(darkMode: false, fontSize: 14, accentColor: "blue")
)
```

## Custom UserDefaults

By default, AsyncObservableUserDefaults uses `UserDefaults.standard`, but you can provide a custom UserDefaults instance:

```swift
let appGroupDefaults = UserDefaults(suiteName: "group.com.example.app")!
let sharedData = AsyncObservableUserDefaults(
    "shared.data",
    initialValue: SharedData.empty,
    userDefaults: appGroupDefaults
)
```

## Handling Default Values

If the key doesn't exist in UserDefaults, the initialValue is used and then stored:

```swift
// If "tutorial.completed" doesn't exist in UserDefaults,
// it will be initialized with false and then stored
let tutorialCompleted = AsyncObservableUserDefaults("tutorial.completed", initialValue: false)
```
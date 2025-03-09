# Persisting Values with UserDefaults

Learn how to use AsyncObservableUserDefaults to persist observable values.

## Overview

AsyncObservable provides a specialized implementation called `AsyncObservableUserDefaults` that automatically persists values to and loads values from UserDefaults. This is provided in a separate module that you can import.

## Basic Usage

`AsyncObservableUserDefaults` works just like ``AsyncObservable``, but it automatically saves values to UserDefaults whenever they change:

```swift
import AsyncObservableUserDefaults

// Create a persisted observable with a key and initial value
let settings = AsyncObservableUserDefaults("app.settings", initialValue: AppSettings.default)

// Read the current value (loads from UserDefaults)
let currentSettings = settings.current

// Update the value (automatically persists to UserDefaults)
settings.update(AppSettings(theme: .dark, notifications: true))

// Observe changes just like with regular AsyncObservable
Task {
    for await updatedSettings in settings.stream {
        print("Settings changed: \(updatedSettings)")
    }
}
```

## Supported Types

`AsyncObservableUserDefaults` can store any type that conforms to `Codable`:

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

By default, `AsyncObservableUserDefaults` uses `UserDefaults.standard`, but you can provide a custom UserDefaults instance:

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
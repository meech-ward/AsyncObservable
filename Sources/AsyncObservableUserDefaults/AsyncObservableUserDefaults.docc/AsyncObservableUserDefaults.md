# ``AsyncObservableUserDefaults``

A Swift package for persisting observable values in UserDefaults.

## Overview

AsyncObservableUserDefaults extends the functionality of AsyncObservable by providing automatic persistence of observable values to and from UserDefaults.

```swift
import AsyncObservableUserDefaults

// Create a persisted observable with a key and initial value
let settings = AsyncObservableUserDefaults("app.settings", initialValue: AppSettings.default)

// Read the current value (loads from UserDefaults)
let currentSettings = settings.current

// Update the value (automatically persists to UserDefaults)
settings.update(AppSettings(theme: .dark, notifications: true))
```

## Topics

### Getting Started

- <doc:UsingUserDefaults>

### Main API

- ``AsyncObservableUserDefaults/AsyncObservableUserDefaults``
# Common Use Cases

Explore practical use cases for AsyncObservable in your Swift applications.

## Overview

``AsyncObservable`` is versatile and can be used in many scenarios where you need to observe and react to state changes. Here are some common use cases to help inspire your implementations.

## Network Request State Management

One common use case is tracking the state of network requests:

```swift
enum RequestState<T> {
    case idle
    case loading
    case success(T)
    case failure(Error)
}

actor NetworkService {
    let requestState = AsyncObservable<RequestState<Data>>(.idle)
    
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

## Cross-Actor Communication

AsyncObservable is ideal for sharing state across actor boundaries:

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

// UI code that monitors progress
Task {
    for await progress in dataProcessor.progress.stream {
        await MainActor.run {
            progressView.progress = Float(progress)
        }
    }
}
```

## Authentication State

Managing user authentication state across your app:

```swift
class AuthManager {
    private let _currentUser = AsyncObservable<User?>(nil)
    var currentUser: AsyncObservableReadOnly<User?> { _currentUser }
    
    // Use unwrappedStream to only react when user is logged in
    var loggedInUserStream: some AsyncSequence<User> {
        _currentUser.unwrappedStream() // Uses AsyncObservable/unwrappedStream()
    }
    
    func login(username: String, password: String) async throws {
        // Authenticate and update state
        let user = try await performLogin(username, password)
        await _currentUser.update(user)
    }
    
    func logout() async {
        await _currentUser.update(nil)
    }
}

// React only when user is logged in
Task {
    for await user in authManager.loggedInUserStream {
        print("User logged in: \(user.username)")
        await loadUserData(for: user)
    }
}
```

## Shared Settings

Manage application settings that need to be accessed from multiple places:

```swift
// Create a persistent settings observable
let appSettings = AsyncObservableUserDefaults("app.settings", initialValue: AppSettings.default)

// Access from anywhere
if appSettings.current.isDebugModeEnabled {
    Logger.logLevel = .debug
}

// Update when settings change
Task {
    for await settings in appSettings.stream {
        applyTheme(settings.theme)
        updateNotificationSettings(settings.notifications)
    }
}

// Use in SwiftUI
struct SettingsView: View {
    let settings: AsyncObservableUserDefaults<AppSettings>
    
    var body: some View {
        Form {
            Toggle("Dark Mode", isOn: Binding(
                get: { settings.observable.darkMode },
                set: { newValue in
                    var updated = settings.current
                    updated.darkMode = newValue
                    settings.update(updated)
                }
            ))
            // Other settings...
        }
    }
}
```
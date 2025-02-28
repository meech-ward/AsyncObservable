# AsyncObservable

Some of the features that Combine used to offer, but using Swift concurrency and @Observable instead. So it's more compatible with modern setups and should work just fine on any platform.
Designed for Swift 6.


A single property that is thread safe and can be observed using async streams or @Observable.

```swift
import AsyncObservable

actor Something {
  let someProperty = AsyncObservable("Hello, world!")

  func funcThatUpdatesProperty() async {
    await someProperty.update("Hello, world! 2")
  }
}

let something = Something()
something.someProperty.value // "Hello, world!"

for await value in something.someProperty.valueStream {
  print(value) // hello world (then whatever the property is updated to)
}


struct SomethingView: View {
  let something: Something // Note: someProperty should be marked with @MainActor for this to work as is
  var body: some View {
    Text(something.someProperty.valueObservable) // hello world (then whatever the property is updated to)
  }
}
```


## Stream

The streams buffering policy defaults to `.unbounded`, so it will "gather" values as soon as you create it. 

```swift
let someProperty = AsyncObservable(1)

let stream = someProperty.valueStream // already has 1
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

let stream = someProperty.valueStream // already has 1
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

let stream = someProperty.valueStream // already has 1
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
for await value in someProperty.valueStream {
 
}
```

## Mutate

Sometimes you just want to mutate the original value instead of having to copy and return a new value. This still updates all the observers correctly and is safe.

```swift
let values = AsyncObservable([1, 2, 3])

values.mutate { $0.append(4) }
```


## Buffering Policy 

The buffering policy defaults to `.unbounded`, but you can change it on init.

```swift
let someProperty = AsyncObservable("Hello, world!", bufferingPolicy: .bufferingNewest(1))
```

## DispatchQueue

You can pass a custom dispatch queue to the initializer, just make sure it's a serial queue. Don't change the queue unless you really need to.

```swift
let someProperty = AsyncObservable("Hello, world!", dispatchQueue: DispatchSerialQueue(label: "SomeQueue"))
```

## UserDefaults

Use the `AsyncObservableUserDefaults` class to store values in UserDefaults. Works just the same as `AsyncObservable`, but automatically saves to UserDefaults and loads from there.

```swift
let someProperty = AsyncObservableUserDefaults("someKey", initialValue: "Hello, world!")
```


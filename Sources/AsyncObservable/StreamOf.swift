/// An asynchronous sequence generated from an underlying `AsyncStream`.
/// Taken from Alamofire https://github.com/Alamofire/Alamofire/blob/2e7a741fc2af29bd833eddd45ee8c461987ff250/Source/Features/Concurrency.swift#L905
/// Modified slightly
/// This allows the async sequence to stop when the task is cancelled and removes the need for a if Task.isCancelled check inside every loop
@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct StreamOf<Element>: AsyncSequence {
  public typealias AsyncIterator = Iterator
  public typealias BufferingPolicy = AsyncStream<Element>.Continuation.BufferingPolicy
  typealias Continuation = AsyncStream<Element>.Continuation

  private let bufferingPolicy: BufferingPolicy
  private let onTermination: (() -> Void)?
  private let builder: (Continuation) -> Void
  private var continuation: AsyncStream<Element>.Continuation?
  private var stream: AsyncStream<Element>?

  init(
    bufferingPolicy: BufferingPolicy = .unbounded,
    buildStreamImmediately: Bool = true,
    onTermination: (() -> Void)? = nil,
    builder: @escaping (Continuation) -> Void
  ) {
    self.bufferingPolicy = bufferingPolicy
    self.onTermination = onTermination
    self.builder = builder
    if buildStreamImmediately {
      let (stream, continuation) = getStreamAndContinuation()
      self.stream = stream
      self.continuation = continuation
    }
  }

  private func getStreamAndContinuation() -> (
    AsyncStream<Element>, AsyncStream<Element>.Continuation?
  ) {
    guard let s = stream, let c = continuation else {
      var continuation: AsyncStream<Element>.Continuation?
      let stream = AsyncStream<Element>(bufferingPolicy: bufferingPolicy) { innerContinuation in
        continuation = innerContinuation
        builder(innerContinuation)
      }
      return (stream, continuation)
    }
    return (s, c)
  }

  public func makeAsyncIterator() -> Iterator {
    let (stream, continuation) = getStreamAndContinuation()

    return Iterator(iterator: stream.makeAsyncIterator()) {
      continuation?.finish()
      onTermination?()
    }
  }

  public struct Iterator: AsyncIteratorProtocol {
    private final class Token {
      private let onDeinit: () -> Void

      init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
      }

      deinit {
        onDeinit()
      }
    }

    private var iterator: AsyncStream<Element>.AsyncIterator
    private let token: Token

    init(iterator: AsyncStream<Element>.AsyncIterator, onCancellation: @escaping () -> Void) {
      self.iterator = iterator
      token = Token(onDeinit: onCancellation)
    }

    public mutating func next() async -> Element? {
      await iterator.next()
    }
  }
}

import Foundation

/// One in-flight refresh. Concurrent callers await the same task.
public actor RefreshGate {
    private var inFlight: Task<Void, Never>?

    public init() {}

    public func run(_ work: @escaping @Sendable () async -> Void) async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task {
            await work()
        }
        inFlight = task
        await task.value
        inFlight = nil
    }
}

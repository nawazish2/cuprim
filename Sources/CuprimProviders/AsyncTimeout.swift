import Foundation
import CuprimCore

public enum AsyncTimeout {
    public static func run<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw ProviderError.timedOut
            }
            guard let result = try await group.next() else {
                throw ProviderError.timedOut
            }
            group.cancelAll()
            return result
        }
    }
}

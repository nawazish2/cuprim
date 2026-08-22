import Foundation
import SQLite3
import CuprimCore

enum SQLiteReader {
    private enum Attempt: Sendable {
        case value(String?)
        case busy
    }

    /// Reads a single string column, retrying while the database is locked.
    ///
    /// The read runs on a detached task rather than inline: sqlite3's busy
    /// handler blocks its calling thread for up to `busyTimeoutMS`, and the
    /// retry backoff used to be `Thread.sleep`. Both stalled a cooperative-pool
    /// thread from inside the four-wide provider refresh task group.
    static func string(
        path: String,
        sql: String,
        bind: String,
        busyTimeoutMS: Int32 = 250,
        retries: Int = 3
    ) async throws -> String? {
        var sawBusy = false
        for attempt in 0..<retries {
            let outcome = try await Task.detached(priority: .utility) {
                try Self.readOnce(path: path, sql: sql, bind: bind, busyTimeoutMS: busyTimeoutMS)
            }.value

            switch outcome {
            case .value(let value):
                return value
            case .busy:
                sawBusy = true
                try? await Task.sleep(for: .milliseconds((attempt + 1) * 80))
            }
        }
        if sawBusy {
            throw ProviderError.unavailable
        }
        return nil
    }

    /// Blocking. Only call from a context that may block its thread.
    private static func readOnce(
        path: String,
        sql: String,
        bind: String,
        busyTimeoutMS: Int32
    ) throws -> Attempt {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK, let db else {
            sqlite3_close(db)
            throw ProviderError.unavailable
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, busyTimeoutMS)

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            return .value(nil)
        }
        defer { sqlite3_finalize(statement) }

        let nsKey = bind as NSString
        sqlite3_bind_text(statement, 1, nsKey.utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        let step = sqlite3_step(statement)
        if step == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                return .value(String(cString: cString))
            }
            return .value(nil)
        }
        if step == SQLITE_BUSY || step == SQLITE_LOCKED {
            return .busy
        }
        return .value(nil)
    }
}

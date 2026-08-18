import Foundation
import SQLite3
import CuprimCore

enum SQLiteReader {
    static func string(
        path: String,
        sql: String,
        bind: String,
        busyTimeoutMS: Int32 = 250,
        retries: Int = 3
    ) throws -> String? {
        var lastBusy = false
        for attempt in 0..<retries {
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
                return nil
            }
            defer { sqlite3_finalize(statement) }

            let nsKey = bind as NSString
            sqlite3_bind_text(statement, 1, nsKey.utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            let step = sqlite3_step(statement)
            if step == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    return String(cString: cString)
                }
                return nil
            }
            if step == SQLITE_BUSY || step == SQLITE_LOCKED {
                lastBusy = true
                let delay = UInt64((attempt + 1) * 80_000_000)
                Thread.sleep(forTimeInterval: Double(delay) / 1_000_000_000)
                continue
            }
            return nil
        }
        if lastBusy {
            throw ProviderError.unavailable
        }
        return nil
    }
}

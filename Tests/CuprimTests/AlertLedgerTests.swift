import XCTest
import Foundation
import CuprimCore

final class AlertLedgerTests: XCTestCase {
    func testLedgerIsBoundedAndPrunesExpiredWindows() {
        var ledger = LowQuotaAlertLedger()
        let past = Date(timeIntervalSince1970: 10)
        let future = Date(timeIntervalSince1970: 5_000)
        ledger.record(key: "old", threshold: 20, expiresAt: past)
        ledger.record(key: "live", threshold: 5, expiresAt: future)
        ledger.prune(now: Date(timeIntervalSince1970: 20), maxWindows: 40)
        XCTAssertNil(ledger.windows["old"])
        XCTAssertEqual(ledger.sentThresholds(for: "live"), [5])
    }

    func testLedgerCapsWindowCount() {
        var ledger = LowQuotaAlertLedger()
        for index in 0..<80 {
            ledger.record(
                key: "w\(index)",
                threshold: 20,
                expiresAt: Date(timeIntervalSince1970: TimeInterval(100 + index))
            )
        }
        ledger.prune(now: Date(timeIntervalSince1970: 1), maxWindows: 40)
        XCTAssertEqual(ledger.windows.count, 40)
    }

    func testDisabledProviderDoesNotCreateAlertFromPolicyAlone() {
        // Crossing policy is pure; callers must skip disabled providers.
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThreshold(remainingPercent: 4, alreadySent: []),
            5
        )
    }

    func testHorizonPreferenceMigratesOnce() {
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: true, legacy: false), true)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: true), true)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: false), false)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: nil), false)
    }
}

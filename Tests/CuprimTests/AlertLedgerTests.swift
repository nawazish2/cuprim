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
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: []).first,
            5
        )
    }

    func testNewlyReachedThresholdsReturnsAllCrossedNotJustMostUrgent() {
        // Regression: dropping straight to 4% with an empty ledger crosses
        // both the 20% and 5% thresholds in one refresh — both must be
        // reported (and recorded), or the un-recorded one re-fires next time.
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: []),
            [5, 20]
        )
    }

    func testNewlyReachedThresholdsDoesNotRefireAnAlreadySentThreshold() {
        // The exact failing input from the double-fire bug: 5% was already
        // sent, remaining is still <= 20%, so 20% alone must be newly reached.
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: [5]),
            [20]
        )
    }

    func testNewlyReachedThresholdsEmptyWhenAllAlreadySent() {
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: [5, 20]),
            []
        )
    }

    func testLedgerRetainsNilExpiryWindowsUntilTTL() {
        // Reset-less metrics (e.g. Claude's Desktop fallback) record a nil
        // expiresAt. Without a TTL fallback, a 5% alert would be muted
        // forever, even across a real quota reset the app never observes.
        var ledger = LowQuotaAlertLedger()
        let recordedAt = Date(timeIntervalSince1970: 1_000)
        ledger.record(key: "reset-less", threshold: 5, expiresAt: nil, now: recordedAt)

        let justUnderTTL = recordedAt.addingTimeInterval(LowQuotaAlertLedger.noExpiryTTL - 1)
        ledger.prune(now: justUnderTTL)
        XCTAssertEqual(ledger.sentThresholds(for: "reset-less"), [5])

        let pastTTL = recordedAt.addingTimeInterval(LowQuotaAlertLedger.noExpiryTTL + 1)
        ledger.prune(now: pastTTL)
        XCTAssertNil(ledger.windows["reset-less"])
    }

    func testHorizonPreferenceMigratesOnce() {
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: true, legacy: false), true)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: true), true)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: false), false)
        XCTAssertEqual(AlertPreferenceMigration.resolved(current: nil, legacy: nil), false)
    }
}

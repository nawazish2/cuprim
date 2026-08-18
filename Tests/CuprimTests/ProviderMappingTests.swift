import XCTest
import Foundation
import CuprimCore

final class ProviderMappingTests: XCTestCase {
    func testClaudeLiveMapping() throws {
        let json = """
        {
          "five_hour": { "utilization": 0.42, "resets_at": "2026-08-18T12:00:00Z" },
          "seven_day": { "utilization": 18, "resets_at": "2026-08-24T12:00:00Z" }
        }
        """.data(using: .utf8)!
        let snapshot = try ClaudeUsageMapping.snapshot(fromLiveJSON: json, subscriptionHint: "pro")
        XCTAssertEqual(snapshot.id, .claude)
        XCTAssertEqual(snapshot.planName, "Pro")
        XCTAssertEqual(snapshot.metrics.count, 2)
        XCTAssertEqual(snapshot.metrics[0].usedFraction ?? -1, 0.42, accuracy: 1e-9)
        XCTAssertEqual(snapshot.metrics[1].usedFraction ?? -1, 0.18, accuracy: 1e-9)
    }

    func testClaudeMalformedThrows() {
        XCTAssertThrowsError(try ClaudeUsageMapping.snapshot(fromLiveJSON: Data("{}".utf8), subscriptionHint: nil))
    }

    func testCodexMapping() throws {
        let json = """
        {
          "plan_type": "plus",
          "rate_limit": {
            "primary_window": { "used_percent": 12, "limit_window_seconds": 18000, "reset_after_seconds": 3600 },
            "secondary_window": { "used_percent": 40, "limit_window_seconds": 604800, "reset_at": 1777000000 }
          }
        }
        """.data(using: .utf8)!
        let snapshot = try CodexUsageMapping.snapshot(fromJSON: json)
        XCTAssertEqual(snapshot.planName, "Plus")
        XCTAssertEqual(snapshot.metrics[0].id, "session")
        XCTAssertEqual(snapshot.metrics[1].id, "weekly")
        XCTAssertEqual(snapshot.metrics[0].usedFraction ?? -1, 0.12, accuracy: 1e-9)
    }

    func testCursorMappingAndDisplayPercent() throws {
        let json = """
        {
          "membershipType": "pro",
          "billingCycleEnd": "2026-09-01T00:00:00Z",
          "individualUsage": {
            "plan": { "autoPercentUsed": 27, "apiPercentUsed": 9, "totalPercentUsed": 18 }
          }
        }
        """.data(using: .utf8)!
        let snapshot = try CursorUsageMapping.snapshot(fromJSON: json)
        XCTAssertEqual(snapshot.metrics.count, 3)
        XCTAssertEqual(snapshot.metrics[0].id, "auto")
        XCTAssertEqual(snapshot.metrics[2].usedFraction ?? -1, 0.18, accuracy: 1e-9)
    }

    func testGrokMapping() throws {
        let json = """
        {
          "config": {
            "creditUsagePercent": 54,
            "billingPeriodEnd": "2026-08-24T00:00:00Z",
            "isUnifiedBillingUser": true
          }
        }
        """.data(using: .utf8)!
        let snapshot = try GrokUsageMapping.snapshot(fromJSON: json, planName: nil)
        XCTAssertEqual(snapshot.planName, "SuperGrok")
        XCTAssertEqual(snapshot.metrics[0].usedFraction ?? -1, 0.54, accuracy: 1e-9)
    }

    func testMalformedResponsesThrowDecode() {
        XCTAssertThrowsError(try CodexUsageMapping.snapshot(fromJSON: Data("[]".utf8)))
        XCTAssertThrowsError(try CursorUsageMapping.snapshot(fromJSON: Data("{}".utf8)))
        XCTAssertThrowsError(try GrokUsageMapping.snapshot(fromJSON: Data("{}".utf8), planName: nil))
        XCTAssertThrowsError(try AntigravityQuotaMapping.metrics(fromSummaryJSON: Data("[]".utf8)))
    }
}

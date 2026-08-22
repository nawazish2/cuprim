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

    func testClaudeMissingUtilizationIsUnknownNotZero() throws {
        // A field the server omits must read as "unknown" (nil), not a
        // confident 0% used — 0% would render green and suppress alerts.
        let json = """
        { "five_hour": { "resets_at": "2026-08-18T12:00:00Z" } }
        """.data(using: .utf8)!
        let snapshot = try ClaudeUsageMapping.snapshot(fromLiveJSON: json, subscriptionHint: nil)
        XCTAssertNil(snapshot.metrics[0].usedFraction)
        XCTAssertNil(snapshot.metrics[0].detail)
    }

    func testClaudeDesktopFallbackDoesNotHardcodeFreePlan() throws {
        let json = """
        { "samples": [ { "t": 1755500000000, "u": { "fh": 42, "sd": 18 } } ] }
        """.data(using: .utf8)!
        let sample = try XCTUnwrap(ClaudeUsageMapping.desktopSample(fromHistoryJSON: json))
        let snapshot = ClaudeUsageMapping.snapshot(fromDesktop: sample)
        XCTAssertNil(snapshot.planName)
    }

    func testClaudeDesktopSampleRejectsMissingTimestamp() {
        // No `t` means we can't know how stale this sample is — treat as
        // "no sample" rather than defaulting to `Date()` (fake freshness).
        let json = """
        { "samples": [ { "u": { "fh": 42, "sd": 18 } } ] }
        """.data(using: .utf8)!
        XCTAssertNil(ClaudeUsageMapping.desktopSample(fromHistoryJSON: json))
    }

    func testClaudeDesktopTimestampDisambiguatesSecondsVsMilliseconds() throws {
        let msJSON = """
        { "samples": [ { "t": 1755500000000, "u": { "fh": 1, "sd": 1 } } ] }
        """.data(using: .utf8)!
        let msSample = try XCTUnwrap(ClaudeUsageMapping.desktopSample(fromHistoryJSON: msJSON))
        XCTAssertEqual(msSample.sampledAt.timeIntervalSince1970, 1755500000, accuracy: 1)

        let secJSON = """
        { "samples": [ { "t": 1755500000, "u": { "fh": 1, "sd": 1 } } ] }
        """.data(using: .utf8)!
        let secSample = try XCTUnwrap(ClaudeUsageMapping.desktopSample(fromHistoryJSON: secJSON))
        XCTAssertEqual(secSample.sampledAt.timeIntervalSince1970, 1755500000, accuracy: 1)
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

    func testCodexMissingUsedPercentIsUnknownNotZero() throws {
        let json = """
        {
          "rate_limit": {
            "primary_window": { "limit_window_seconds": 18000 }
          }
        }
        """.data(using: .utf8)!
        let snapshot = try CodexUsageMapping.snapshot(fromJSON: json)
        XCTAssertNil(snapshot.metrics[0].usedFraction)
        XCTAssertNil(snapshot.metrics[0].detail)
    }

    func testCodexResetAtDisambiguatesSecondsVsMilliseconds() throws {
        let secondsJSON = """
        {
          "rate_limit": {
            "primary_window": { "used_percent": 10, "limit_window_seconds": 18000, "reset_at": 1755500000 }
          }
        }
        """.data(using: .utf8)!
        let secondsSnapshot = try CodexUsageMapping.snapshot(fromJSON: secondsJSON)
        XCTAssertEqual(secondsSnapshot.metrics[0].resetsAt?.timeIntervalSince1970 ?? 0, 1755500000, accuracy: 1)

        let msJSON = """
        {
          "rate_limit": {
            "primary_window": { "used_percent": 10, "limit_window_seconds": 18000, "reset_at": 1755500000000 }
          }
        }
        """.data(using: .utf8)!
        let msSnapshot = try CodexUsageMapping.snapshot(fromJSON: msJSON)
        XCTAssertEqual(msSnapshot.metrics[0].resetsAt?.timeIntervalSince1970 ?? 0, 1755500000, accuracy: 1)
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

    func testCursorMissingTotalUsesWorstOfAutoAndAPI() throws {
        // Auto fully exhausted, API untouched: averaging would report a
        // healthy-looking 50% and mask the real exhaustion.
        let json = """
        {
          "individualUsage": {
            "plan": { "autoPercentUsed": 100, "apiPercentUsed": 0 }
          }
        }
        """.data(using: .utf8)!
        let snapshot = try CursorUsageMapping.snapshot(fromJSON: json)
        let total = try XCTUnwrap(snapshot.metrics.first { $0.id == "total" })
        XCTAssertEqual(total.usedFraction ?? -1, 1.0, accuracy: 1e-9)
    }

    func testCursorUnlimitedIsUnknownNotZeroPercent() throws {
        let json = """
        { "isUnlimited": true }
        """.data(using: .utf8)!
        let snapshot = try CursorUsageMapping.snapshot(fromJSON: json)
        let total = try XCTUnwrap(snapshot.metrics.first { $0.id == "total" })
        XCTAssertNil(total.usedFraction)
        XCTAssertEqual(total.detail, "Unlimited")
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
    }

    func testPlanNamePreservesCompoundNames() {
        // A compound plan id must not collapse to the substring it happens
        // to contain — "pro_plus" is its own tier, distinct from "pro".
        XCTAssertEqual(PlanNameFormatting.prettyPlan("pro_plus"), "Pro Plus")
        XCTAssertEqual(PlanNameFormatting.prettyPlan("free_trial"), "Free Trial")
        XCTAssertEqual(PlanNameFormatting.prettyPlan("team_pro"), "Team Pro")
        XCTAssertEqual(PlanNameFormatting.prettyPlan("pro"), "Pro")
        XCTAssertEqual(PlanNameFormatting.prettyPlan("FREE"), "Free")
    }
}

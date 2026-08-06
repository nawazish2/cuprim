import XCTest
import TokenBarCore

/// Exercises **shipped** pure logic in TokenBarCore — not a mirror reimplementation.
final class ShippedLogicTests: XCTestCase {
    // MARK: - Utilization

    func testClamp01Bounds() {
        XCTAssertEqual(Utilization.clamp01(-0.5), 0)
        XCTAssertEqual(Utilization.clamp01(0), 0)
        XCTAssertEqual(Utilization.clamp01(0.42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.clamp01(1), 1)
        XCTAssertEqual(Utilization.clamp01(1.5), 1)
    }

    func testFractionFromRawPercentOrUnit() {
        // Dual-scale only for ambiguous APIs: >1 ⇒ percent, ≤1 ⇒ unit fraction.
        XCTAssertEqual(Utilization.fraction(fromRaw: 0.42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromRaw: 42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromRaw: 0), 0)
        XCTAssertEqual(Utilization.fraction(fromRaw: 100), 1)
        XCTAssertEqual(Utilization.fraction(fromRaw: 150), 1)
        XCTAssertEqual(Utilization.fraction(fromRaw: -10), 0)
        // Dual-scale treats 1 as 100% unit — callers with whole percents must not use this.
        XCTAssertEqual(Utilization.fraction(fromRaw: 1), 1, accuracy: 1e-12)
    }

    /// Known 0…100 provider fields must use `fraction(fromPercent:)` so 1 means 1%.
    func testFractionFromWholePercentBoundary() {
        XCTAssertEqual(Utilization.fraction(fromPercent: 1), 0.01, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 0.5), 0.005, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 12), 0.12, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 100), 1, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 0), 0, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 150), 1, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: -5), 0, accuracy: 1e-12)

        // Labels stay consistent with percent scale (1% used → 99% left).
        let onePercent = Utilization.fraction(fromPercent: 1)
        XCTAssertEqual(QuotaFormatting.usedPercentLabel(usedFraction: onePercent), "1%")
        XCTAssertEqual(QuotaFormatting.remainingLabel(usedFraction: onePercent), "99%")
    }

    /// Claude Desktop / Codex / Cursor / Grok percent fields map through fromPercent.
    func testKnownProviderPercentFieldsUsePercentScale() {
        // Simulate Claude Desktop fh/sd = 1 (1% used), not dual-scale.
        let desktop = Utilization.fraction(fromPercent: 1)
        XCTAssertEqual(desktop, 0.01, accuracy: 1e-12)
        XCTAssertNotEqual(desktop, Utilization.fraction(fromRaw: 1))

        // Codex used_percent = 1
        let codex = Utilization.fraction(fromPercent: 1)
        XCTAssertEqual(Utilization.usedPercent(usedFraction: codex), 1)

        // Cursor autoPercentUsed = 4.01
        let cursor = Utilization.fraction(fromPercent: 4.01)
        XCTAssertEqual(cursor, 0.0401, accuracy: 1e-9)

        // Grok creditUsagePercent = 1
        let grok = Utilization.fraction(fromPercent: 1)
        XCTAssertEqual(QuotaFormatting.usedPercentLabel(usedFraction: grok), "1%")
    }

    func testRemainingAndUsedPercent() {
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 0.42), 58)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 1), 0)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 0), 100)
        XCTAssertEqual(Utilization.usedPercent(usedFraction: 0.42), 42)
        // Clamp over-range used fractions before percent conversion
        XCTAssertEqual(Utilization.usedPercent(usedFraction: 1.5), 100)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: -0.2), 100)
    }

    // MARK: - QuotaFormatting (shipped)

    func testRemainingAndUsedLabels() {
        XCTAssertEqual(QuotaFormatting.remainingLabel(usedFraction: 0.42), "58%")
        XCTAssertEqual(QuotaFormatting.usedPercentLabel(usedFraction: 0.42), "42%")
        XCTAssertEqual(QuotaFormatting.remainingLabel(usedFraction: nil), "—")
        XCTAssertEqual(QuotaFormatting.usedPercentLabel(usedFraction: nil), "—")
    }

    func testResetLabelNearbyIsRelativeOnly() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let soon = now.addingTimeInterval(2 * 86_400 + 3 * 3600)
        let label = QuotaFormatting.resetLabel(for: soon, absolute: true, relativeTo: now)
        XCTAssertTrue(label.hasPrefix("Resets in "), label)
        // Production does not append absolute with " · " for nearby windows.
        XCTAssertFalse(label.contains("·"), label)
    }

    func testResetLabelFarIsAbsoluteWhenEnabled() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let far = now.addingTimeInterval(10 * 86_400)
        let label = QuotaFormatting.resetLabel(for: far, absolute: true, relativeTo: now)
        XCTAssertTrue(label.hasPrefix("Resets "), label)
        XCTAssertFalse(label.hasPrefix("Resets in "), label)
    }

    func testResetLabelFarFallsBackToRelativeWhenAbsoluteDisabled() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let far = now.addingTimeInterval(10 * 86_400)
        let label = QuotaFormatting.resetLabel(for: far, absolute: false, relativeTo: now)
        XCTAssertTrue(label.hasPrefix("Resets in "), label)
    }

    func testResetLabelPastIsSoon() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let past = now.addingTimeInterval(-60)
        XCTAssertEqual(QuotaFormatting.resetLabel(for: past, relativeTo: now), "Resets soon")
        XCTAssertEqual(QuotaFormatting.resetLabel(for: nil), "")
    }

    // MARK: - Provider status mapping

    func testNotLoggedInErrorMapsToNotLoggedInStatus() {
        let snap = ProviderStatusMapping.snapshot(for: .grok, error: ProviderError.notLoggedIn)
        XCTAssertEqual(snap.id, .grok)
        if case .notLoggedIn = snap.status {
            // ok
        } else {
            XCTFail("expected .notLoggedIn, got \(snap.status)")
        }
        XCTAssertTrue(snap.metrics.isEmpty)
    }

    func testHTTPErrorMapsToErrorStatus() {
        let snap = ProviderStatusMapping.snapshot(
            for: .claude,
            error: ProviderError.http(500, "boom")
        )
        if case .error(let message) = snap.status {
            XCTAssertTrue(message.contains("500"), message)
        } else {
            XCTFail("expected .error, got \(snap.status)")
        }
    }

    func testGenericErrorMapsToErrorStatus() {
        struct E: Error {}
        let snap = ProviderStatusMapping.snapshot(for: .cursor, error: E())
        if case .error = snap.status {
            // ok
        } else {
            XCTFail("expected .error for generic Error")
        }
    }

    // MARK: - Codex window classifier

    func testCodexWindowClassification() {
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 5 * 3600), .session)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 7 * 86_400), .weekly)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 30 * 86_400), .period)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 0), .primary)
        XCTAssertEqual(CodexWindowClassifier.label(for: .session), "Session limit")
        XCTAssertEqual(CodexWindowClassifier.label(for: .period), "Period limit")
        XCTAssertEqual(CodexWindowClassifier.label(for: .primary), "Usage limit")
    }
}

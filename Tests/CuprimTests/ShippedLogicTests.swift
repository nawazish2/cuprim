import XCTest
import Foundation
import CuprimCore
import CuprimProviders

final class ShippedLogicTests: XCTestCase {
    func testClamp01Bounds() {
        XCTAssertEqual(Utilization.clamp01(-0.5), 0)
        XCTAssertEqual(Utilization.clamp01(0), 0)
        XCTAssertEqual(Utilization.clamp01(0.42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.clamp01(1), 1)
        XCTAssertEqual(Utilization.clamp01(1.5), 1)
    }

    func testFractionFromRawPercentOrUnit() {
        XCTAssertEqual(Utilization.fraction(fromRaw: 0.42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromRaw: 42), 0.42, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromRaw: 0), 0)
        XCTAssertEqual(Utilization.fraction(fromRaw: 100), 1)
        XCTAssertEqual(Utilization.fraction(fromRaw: 150), 1)
        XCTAssertEqual(Utilization.fraction(fromRaw: -10), 0)
        XCTAssertEqual(Utilization.fraction(fromRaw: 1), 1, accuracy: 1e-12)
    }

    func testFractionFromWholePercentBoundary() {
        XCTAssertEqual(Utilization.fraction(fromPercent: 1), 0.01, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 0.5), 0.005, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 12), 0.12, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 100), 1, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 0), 0, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: 150), 1, accuracy: 1e-12)
        XCTAssertEqual(Utilization.fraction(fromPercent: -5), 0, accuracy: 1e-12)

        let onePercent = Utilization.fraction(fromPercent: 1)
        XCTAssertEqual(QuotaFormatting.usedPercentLabel(usedFraction: onePercent), "1%")
        XCTAssertEqual(QuotaFormatting.remainingLabel(usedFraction: onePercent), "99%")
    }

    func testRemainingAndUsedPercent() {
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 0.42), 58)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 1), 0)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: 0), 100)
        XCTAssertEqual(Utilization.usedPercent(usedFraction: 0.42), 42)
        XCTAssertEqual(Utilization.usedPercent(usedFraction: 1.5), 100)
        XCTAssertEqual(Utilization.remainingPercent(usedFraction: -0.2), 100)
    }

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

    func testSignedOutMapsToFailedKind() {
        let snap = ProviderStatusMapping.snapshot(for: .grok, error: ProviderError.signedOut)
        XCTAssertEqual(snap.status, .failed(.signedOut))
        XCTAssertTrue(snap.metrics.isEmpty)
    }

    func testHTTPErrorMapsToUnavailable() {
        let snap = ProviderStatusMapping.snapshot(for: .claude, error: ProviderError.http(500))
        XCTAssertEqual(snap.status, .failed(.unavailable))
    }

    func testOfflineErrorMapsToOffline() {
        let snap = ProviderStatusMapping.snapshot(for: .cursor, error: URLError(.notConnectedToInternet))
        XCTAssertEqual(snap.status, .failed(.offline))
        XCTAssertTrue(ProviderStatusMapping.isOffline(URLError(.notConnectedToInternet)))
        XCTAssertFalse(ProviderStatusMapping.isOffline(ProviderError.signedOut))
    }

    func testSessionExpiredDistinctFromSignedOut() {
        let expired = ProviderStatusMapping.snapshot(for: .codex, error: ProviderError.sessionExpired)
        XCTAssertEqual(expired.status, .failed(.sessionExpired))
        XCTAssertNotEqual(expired.status, .failed(.signedOut))
    }

    func testRateLimitedAndMalformed() {
        XCTAssertEqual(ProviderStatusMapping.kind(for: ProviderError.rateLimited), .rateLimited)
        XCTAssertEqual(ProviderStatusMapping.kind(for: ProviderError.decode), .malformedResponse)
        XCTAssertEqual(HTTPResponseMapping.kind(statusCode: 429), .rateLimited)
        XCTAssertEqual(HTTPResponseMapping.kind(statusCode: 401, credentialsPresent: true), .sessionExpired)
        XCTAssertEqual(HTTPResponseMapping.kind(statusCode: 401, credentialsPresent: false), .signedOut)
    }

    func testGenericErrorMapsToUnavailable() {
        struct E: Error {}
        let snap = ProviderStatusMapping.snapshot(for: .cursor, error: E())
        XCTAssertEqual(snap.status, .failed(.unavailable))
    }

    func testCodexWindowClassification() {
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 5 * 3600), .session)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 7 * 86_400), .weekly)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 30 * 86_400), .period)
        XCTAssertEqual(CodexWindowClassifier.kind(windowSeconds: 0), .primary)
        XCTAssertEqual(CodexWindowClassifier.label(for: .session), "Session limit")
        XCTAssertEqual(CodexWindowClassifier.label(for: .period), "Period limit")
        XCTAssertEqual(CodexWindowClassifier.label(for: .primary), "Usage limit")
    }

    func testLowQuotaAlertEmitsMostUrgentOnly() {
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: []).first,
            5
        )
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 18, alreadySent: []).first,
            20
        )
        XCTAssertTrue(LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: [5, 20]).isEmpty)
        XCTAssertEqual(
            LowQuotaAlertPolicy.newlyReachedThresholds(remainingPercent: 4, alreadySent: [20]).first,
            5
        )
    }

    func testStalePolicyAgreesWithRefreshInterval() {
        XCTAssertEqual(StalePolicy.thresholdMinutes(refreshMinutes: 2), 6)
        XCTAssertEqual(StalePolicy.thresholdMinutes(refreshMinutes: 10), 30)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertTrue(StalePolicy.isStale(now.addingTimeInterval(-7 * 60), refreshMinutes: 2, relativeTo: now))
        XCTAssertFalse(StalePolicy.isStale(now.addingTimeInterval(-3 * 60), refreshMinutes: 2, relativeTo: now))
    }

    func testRefreshMergeKeepsLastGoodOnTransientFailure() {
        let good = ProviderSnapshot(
            id: .cursor,
            planName: "Pro",
            metrics: [Metric(id: "total", label: "Total", usedFraction: 0.4)],
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 10)
        )
        let incoming = ProviderSnapshot.failed(.cursor, .offline, at: Date(timeIntervalSince1970: 20))
        let merged = RefreshMergePolicy.merge(previous: good, incoming: incoming)
        XCTAssertEqual(merged.status, .ok)
        XCTAssertEqual(merged.metrics.first?.usedFraction ?? 0, 0.4, accuracy: 1e-9)
        XCTAssertFalse(RefreshMergePolicy.shouldAlert(from: incoming))
        XCTAssertTrue(RefreshMergePolicy.shouldAlert(from: good))
    }

    func testRefreshMergeReplacesOnSignedOut() {
        let good = ProviderSnapshot.empty(.codex, status: .ok, at: Date(timeIntervalSince1970: 10))
        let incoming = ProviderSnapshot.failed(.codex, .signedOut, at: Date(timeIntervalSince1970: 20))
        let merged = RefreshMergePolicy.merge(previous: good, incoming: incoming)
        XCTAssertEqual(merged.status, .failed(.signedOut))
    }

    func testRefreshMergeKeepsLastGoodWhenIncomingOKHasNoMetrics() {
        // An `.ok` snapshot with zero metrics is not real data (e.g. a
        // partially-decoded response) and must not wipe last-good meters.
        let good = ProviderSnapshot(
            id: .claude,
            planName: "Max",
            metrics: [Metric(id: "session", label: "Session", usedFraction: 0.3)],
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 10)
        )
        let emptyOK = ProviderSnapshot.empty(.claude, status: .ok, at: Date(timeIntervalSince1970: 20))
        let merged = RefreshMergePolicy.merge(previous: good, incoming: emptyOK)
        XCTAssertEqual(merged.metrics.first?.usedFraction ?? -1, 0.3, accuracy: 1e-9)
    }

    func testMenuBarSeverityWarnsOnPartialFailureEvenWhenUsageIsLow() {
        // One provider failing shouldn't be invisible just because another
        // provider's usage number happens to be healthy.
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: 0.1, hasVisibleError: true, hasVisibleOK: true, isRefreshing: false),
            .warning
        )
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: nil, hasVisibleError: true, hasVisibleOK: true, isRefreshing: false),
            .warning
        )
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: nil, hasVisibleError: true, hasVisibleOK: false, isRefreshing: false),
            .error
        )
    }

    func testMenuBarTooltipDoesNotContradictRemaining() {
        let text = MenuBarTooltip.text(remainingPercent: 4, severity: .critical)
        XCTAssertEqual(text, "Cuprim · 4% left")
        XCTAssertFalse(text.contains("Limit reached"))
        XCTAssertEqual(MenuBarTooltip.text(remainingPercent: nil, severity: .error), "Cuprim · Unavailable")
    }

    func testMenuBarSeverityFromUsage() {
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: 0.96, hasVisibleError: false, hasVisibleOK: true, isRefreshing: false),
            .critical
        )
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: 0.82, hasVisibleError: false, hasVisibleOK: true, isRefreshing: false),
            .warning
        )
        XCTAssertEqual(
            MenuBarTooltip.severity(worstUsedFraction: nil, hasVisibleError: true, hasVisibleOK: false, isRefreshing: false),
            .error
        )
    }
}

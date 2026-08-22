import XCTest
import Foundation
import CuprimCore

/// Covers the presentation decisions that used to live in SwiftUI views, where
/// they were made by string-matching display copy and so had no tests.
final class PresentationLogicTests: XCTestCase {
    private func snapshot(_ resets: [Date?]) -> ProviderSnapshot {
        ProviderSnapshot(
            id: .claude,
            metrics: resets.enumerated().map { index, reset in
                Metric(id: "m\(index)", label: "Metric \(index)", usedFraction: 0.5, resetsAt: reset)
            },
            status: .ok,
            fetchedAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Metric.kind

    func testTotalMetricIsRecognizedFromIDNotLabel() {
        XCTAssertEqual(Metric(id: "total", label: "Total").kind, .total)
        // The label is display copy and must not decide this.
        XCTAssertEqual(Metric(id: "session", label: "Total").kind, .window)
        XCTAssertEqual(Metric(id: "weekly", label: "Weekly limit").kind, .window)
    }

    // MARK: - ProviderSnapshot.resetPresentation

    func testNoResetDatesMeansNoResetRows() {
        let presentation = snapshot([nil, nil]).resetPresentation()
        XCTAssertNil(presentation.shared)
        XCTAssertFalse(presentation.perMetric)
    }

    func testSingleResetIsShared() {
        let date = Date(timeIntervalSince1970: 10_000)
        let presentation = snapshot([date]).resetPresentation()
        XCTAssertEqual(presentation.shared, date)
        XCTAssertFalse(presentation.perMetric)
    }

    func testIdenticalResetsShareOneRow() {
        let date = Date(timeIntervalSince1970: 10_000)
        let presentation = snapshot([date, date]).resetPresentation()
        XCTAssertEqual(presentation.shared, date)
        XCTAssertFalse(presentation.perMetric)
    }

    /// Two windows reported seconds apart are the same moment to a reader, so
    /// one combined row is honest.
    func testNearlyIdenticalResetsShareOneRowAndReportTheEarliest() {
        let first = Date(timeIntervalSince1970: 10_000)
        let second = first.addingTimeInterval(30)
        let presentation = snapshot([second, first]).resetPresentation()
        XCTAssertEqual(presentation.shared, first)
        XCTAssertFalse(presentation.perMetric)
    }

    func testGenuinelyDifferentResetsGetPerMetricRows() {
        let first = Date(timeIntervalSince1970: 10_000)
        let second = first.addingTimeInterval(5 * 60 * 60)
        let presentation = snapshot([first, second]).resetPresentation()
        XCTAssertNil(presentation.shared)
        XCTAssertTrue(presentation.perMetric)
    }

    /// Only one metric carries a reset, so there is nothing to lay out per
    /// metric — but it is still a real shared reset.
    func testOneDatedMetricAmongUndatedOnesIsShared() {
        let date = Date(timeIntervalSince1970: 10_000)
        let presentation = snapshot([date, nil, nil]).resetPresentation()
        XCTAssertEqual(presentation.shared, date)
        XCTAssertFalse(presentation.perMetric)
    }
}

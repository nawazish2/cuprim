import XCTest
import Foundation
import CuprimCore

final class BurnRateTests: XCTestCase {
    /// Aligned to the 15-minute ETA granularity so rounding is a no-op and the
    /// expected instants stay readable.
    private let base = Date(timeIntervalSince1970: 1_000_800)

    private func samples(_ points: [(hours: Double, used: Double)]) -> [BurnSample] {
        points.map {
            BurnSample(at: base.addingTimeInterval($0.hours * 3_600), usedFraction: $0.used)
        }
    }

    private func hours(_ value: Double) -> Date {
        base.addingTimeInterval(value * 3_600)
    }

    // MARK: - Real projections

    /// 0.2/hr from 30% used leaves 3.5h of headroom, so the cap lands 1.5h
    /// before the window would have reset.
    func testSteadyBurnCrossingBeforeReset() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.20), (1.0, 0.30)]),
            resetsAt: hours(6),
            now: hours(1)
        )
        XCTAssertEqual(result, .exhausts(at: hours(4.5), beforeReset: 1.5 * 3_600))
    }

    /// The window turns over at the same instant the cap would be hit, so this
    /// is not an exhaustion.
    func testCrossingExactlyAtResetIsWithinLimit() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.20), (1.0, 0.30)]),
            resetsAt: hours(4.5),
            now: hours(1)
        )
        guard case .withinLimit(let projected) = result else {
            return XCTFail("expected withinLimit, got \(result)")
        }
        XCTAssertEqual(projected, 1.0, accuracy: 1e-9)
    }

    func testSlowBurnReportsProjectedUseAtReset() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.12), (1.0, 0.14)]),
            resetsAt: hours(5),
            now: hours(1)
        )
        guard case .withinLimit(let projected) = result else {
            return XCTFail("expected withinLimit, got \(result)")
        }
        // 0.14 now + 0.04/hr over the remaining 4h.
        XCTAssertEqual(projected, 0.30, accuracy: 1e-9)
    }

    func testFlatUsageStaysAtItsCurrentLevel() {
        let result = BurnRate.project(
            samples: samples([(0, 0.20), (0.5, 0.20), (1.0, 0.20)]),
            resetsAt: hours(6),
            now: hours(1)
        )
        guard case .withinLimit(let projected) = result else {
            return XCTFail("expected withinLimit, got \(result)")
        }
        XCTAssertEqual(projected, 0.20, accuracy: 1e-9)
    }

    /// This is the case that justifies least squares: first-vs-last would read
    /// 0.14/hr because the final sample dips, while the real trend is 0.152/hr.
    /// The fitted ETA must therefore be meaningfully earlier than the two-point
    /// one, not equal to it.
    func testNoisySeriesUsesFittedSlopeNotEndpoints() {
        let result = BurnRate.project(
            samples: samples([(0, 0.20), (0.25, 0.25), (0.5, 0.30), (0.75, 0.35), (1.0, 0.34)]),
            resetsAt: hours(12),
            now: hours(1)
        )
        guard case .exhausts(let at, _) = result else {
            return XCTFail("expected exhausts, got \(result)")
        }
        let twoPointETA = hours(1).addingTimeInterval(0.66 / 0.14 * 3_600)
        let fittedETA = hours(1).addingTimeInterval(0.66 / 0.152 * 3_600)
        XCTAssertLessThan(at, twoPointETA)
        XCTAssertEqual(at.timeIntervalSince(fittedETA), 0, accuracy: BurnRate.etaGranularity)
    }

    func testUnsortedInputMatchesSortedInput() {
        let points: [(hours: Double, used: Double)] = [(0, 0.10), (0.5, 0.20), (1.0, 0.30)]
        let sorted = BurnRate.project(samples: samples(points), resetsAt: hours(6), now: hours(1))
        let shuffled = BurnRate.project(
            samples: samples(Array(points.reversed())),
            resetsAt: hours(6),
            now: hours(1)
        )
        XCTAssertEqual(sorted, shuffled)
    }

    // MARK: - Refusals

    func testEmptyInputIsUnknown() {
        XCTAssertEqual(
            BurnRate.project(samples: [], resetsAt: hours(6), now: hours(1)),
            .unknown(.tooFewSamples)
        )
    }

    func testSingleSampleIsUnknown() {
        XCTAssertEqual(
            BurnRate.project(samples: samples([(1.0, 0.30)]), resetsAt: hours(6), now: hours(1)),
            .unknown(.tooFewSamples)
        )
    }

    func testTwoSamplesAreTooFewEvenWhenFarApart() {
        XCTAssertEqual(
            BurnRate.project(
                samples: samples([(0, 0.10), (1.0, 0.30)]),
                resetsAt: hours(6),
                now: hours(1)
            ),
            .unknown(.tooFewSamples)
        )
    }

    func testShortSpanIsUnknown() {
        // Three samples, but only 10 minutes of coverage.
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.08, 0.12), (0.1667, 0.14)]),
            resetsAt: hours(6),
            now: hours(0.1667)
        )
        XCTAssertEqual(result, .unknown(.spanTooShort))
    }

    func testStaleNewestSampleIsUnknown() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.20), (1.0, 0.30)]),
            resetsAt: hours(6),
            now: hours(1.6)
        )
        XCTAssertEqual(result, .unknown(.stale))
    }

    /// A reset already in the past means these readings describe a window that
    /// is over.
    func testResetAlreadyPassedIsUnknown() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.20), (1.0, 0.30)]),
            resetsAt: hours(0.5),
            now: hours(1)
        )
        XCTAssertEqual(result, .unknown(.stale))
    }

    func testMissingResetTimeIsUnknown() {
        let result = BurnRate.project(
            samples: samples([(0, 0.10), (0.5, 0.20), (1.0, 0.30)]),
            resetsAt: nil,
            now: hours(1)
        )
        XCTAssertEqual(result, .unknown(.noResetTime))
    }

    func testAlreadyExhaustedIsUnknown() {
        let result = BurnRate.project(
            samples: samples([(0, 0.90), (0.5, 0.95), (1.0, 1.0)]),
            resetsAt: hours(6),
            now: hours(1)
        )
        XCTAssertEqual(result, .unknown(.alreadyExhausted))
    }

    /// Usage falling inside one window means the window segmentation is wrong.
    /// Reporting comfort here would be a confident wrong answer.
    func testDecreasingUsageIsUnknownNotReassuring() {
        let result = BurnRate.project(
            samples: samples([(0, 0.50), (0.5, 0.40), (1.0, 0.30)]),
            resetsAt: hours(6),
            now: hours(1)
        )
        XCTAssertEqual(result, .unknown(.usageDecreased))
    }
}

import Foundation
import Observation
import CuprimCore

/// UI-only state that must survive panel open/close (tab selection, etc.).
@MainActor
@Observable
final class DashboardUIState {
    var selectedTab: ProviderTab = .overview
    /// Bumped by `PanelController.show()` so the dashboard's `ScrollView`
    /// resets to the top on every open — the hosting view is reused across
    /// show/hide, so a scroll position from a previous session would
    /// otherwise persist and clip the first card's header.
    var scrollResetToken = 0
}

import Foundation
import Observation
import CuprimCore

/// UI-only state that must survive panel open/close (tab selection, etc.).
@MainActor
@Observable
final class DashboardUIState {
    var selectedTab: ProviderTab = .overview
}

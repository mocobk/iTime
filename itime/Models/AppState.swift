import Observation

/// Shared app state that both AppDelegate and MenuBarPopoverView can access.
/// Allows AppDelegate (right-click menu) to control the popover's settings view.
@Observable
@MainActor
final class AppState {
    static let shared = AppState()
    
    /// Whether the popover should show the settings view.
    var showSettings = false
}

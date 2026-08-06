import AppKit

/// Custom NSApplication so Dock / system “About” opens our credits window
/// instead of the stock About panel.
@objc(TokenBarApplication)
final class TokenBarApplication: NSApplication {
    override func orderFrontStandardAboutPanel(
        options dictionary: [NSApplication.AboutPanelOptionKey: Any] = [:]
    ) {
        AboutWindowController.show()
    }
}

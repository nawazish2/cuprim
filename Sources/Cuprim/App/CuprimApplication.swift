import AppKit

/// Custom NSApplication so Dock / system “About” opens our credits window
/// instead of the stock About panel.
@objc(CuprimApplication)
final class CuprimApplication: NSApplication {
    override func orderFrontStandardAboutPanel(
        options dictionary: [NSApplication.AboutPanelOptionKey: Any] = [:]
    ) {
        AboutWindowController.show()
    }
}

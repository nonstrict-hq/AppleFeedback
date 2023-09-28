#  Closing NSPanel on inactive app, hides parent window

On Sonoma, closing an NSPanel that is the child of a parent NSWindow in an inactive application, also hides the parent window.

This issue seems to be new to Sonoma (macOS 14.0), it doesn't happen on Ventura (macOS 13.5).

In code, I've created a panel, and added it as a child to a window.

    self.panel = NSPanel(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: true)
    self.view.window!.addChildWindow(self.panel, ordered: .above)

Then, when the app is no longer the active app, it tries to close the panel, this also closes the parent window.

    self.panel.orderOut(nil)

The parent window shouldn't be closed, it should stay visible (like it does on Ventura).

This only happens on Sonoma, when the app is not active.
It only happens when the styleMask of the NSPanel doesn't include [.utilityWindow,.titled], including both fixes the problem. 

Reproduction steps with attached project.

- Run the project
- The app shows a single NSWindow
- Once the app has launched, click on Xcode to deactivate the test app
- After 1 second, the app opens an NSPanel
- After 3 seconds, the app closes the NSPanel
- Sonoma (incorrectly) also hides the parent NSWindow

## Feedback Assistant / Radar

Submitted as feedback to Apple with id: FB13211617


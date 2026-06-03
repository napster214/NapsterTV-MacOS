import SwiftUI
import AppKit

extension Notification.Name {
    static let floatingStateChanged = Notification.Name("floatingStateChanged")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var floatingMenuItem: NSMenuItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)

        // 手动创建窗口菜单，这样可以动态更新标题
        DispatchQueue.main.async {
            let menu = NSMenu()
            menu.title = "窗口"
            let item = NSMenuItem(title: "置顶窗口", action: #selector(self.toggleFloating), keyEquivalent: "p")
            item.target = self
            menu.addItem(item)
            self.floatingMenuItem = item

            if let mainMenu = NSApp.mainMenu {
                // 插入到帮助菜单之前
                let index = mainMenu.items.count - 1
                let menuItem = NSMenuItem()
                menuItem.submenu = menu
                mainMenu.insertItem(menuItem, at: max(index, 0))
            }
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.command), !flags.contains(.option), !flags.contains(.control),
               let chars = event.charactersIgnoringModifiers, chars == "p" {
                AppDelegate.toggleFloatingAction()
                return nil
            }
            return event
        }

        DispatchQueue.main.async {
            for window in NSApp.windows {
                let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                let windowWidth: CGFloat = 1200
                let windowHeight: CGFloat = 800
                let x = screenFrame.midX - windowWidth / 2
                let y = screenFrame.midY - windowHeight / 2
                window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    @objc func toggleFloating() {
        AppDelegate.toggleFloatingAction()
    }

    static func toggleFloatingAction() {
        guard let window = NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
        let isFloating = window.level == .floating
        window.level = isFloating ? .normal : .floating

        // 更新菜单项文字
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.floatingMenuItem?.title = isFloating ? "置顶窗口" : "取消置顶"
        }

        NotificationCenter.default.post(name: .floatingStateChanged, object: nil, userInfo: ["isFloating": !isFloating])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct NapsterTVApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

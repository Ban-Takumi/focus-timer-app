//
//  FocusTimerApp.swift
//  FocusTimer
//
//  Created by Takumi Ban on 2026/06/25.
//

import SwiftUI

@main
struct FocusTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var mainWindow: NSWindow?
    let sharedViewModel = TimerViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Popoverのセットアップ (ContentViewに共通のViewModelを渡す)
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TimerView(viewModel: sharedViewModel))

        // メニューバーアイコンのセットアップ
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Focus Timer")
            button.action = #selector(statusBarButtonClicked(sender:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            // 右クリック: メニューを表示
            showMenu()
        } else {
            // 左クリック: ポップオーバーをトグル
            togglePopover(sender)
        }
    }

    func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "アプリを開く", action: #selector(openMainWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil // クリック処理が終わったらメニューを解除
    }

    @objc func openMainWindow() {
        // 既にウィンドウがあれば最前面に出すだけ
        if mainWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.setFrameAutosaveName("Main Window")
            // 同じViewModelを共有
            window.contentView = NSHostingView(rootView: ContentView(viewModel: sharedViewModel))
            window.title = "Focus Timer"
            window.isReleasedWhenClosed = false
            self.mainWindow = window
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // ポップオーバーが開いていれば閉じる
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
}

//
//  language_switchApp.swift
//  language_switch
//
//  Created by jamesw_yb on 2025/11/23.
//

import SwiftUI

@main
struct language_switchApp: App {
    // We need a strong reference to the status item to keep it alive
    @StateObject private var menuBarManager = MenuBarManager()
    
    var body: some Scene {
        // No WindowGroup or Settings scene needed here as we manage it manually
        // to avoid SwiftUI warnings and ensure correct behavior for Menu Bar apps.
        Settings {
            EmptyView()
        }
    }
}

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var profileManager = ProfileManager.shared
    private var settingsWindow: NSWindow?
    
    override init() {
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Language Switcher")
            button.action = #selector(handleButtonClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateIcon()
    }
    
    @objc private func handleButtonClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            cycleProfile()
        }
    }
    
    private func cycleProfile() {
        if let nextProfile = profileManager.cycleToNextProfile() {
            InputSourceManager.shared.applyProfile(inputSourceIDs: nextProfile.inputSourceIDs)
            updateIcon()
            
            // Optional: Show a notification or temporary text to indicate change
            print("Switched to profile: \(nextProfile.name)")
        } else {
            // If no profiles, maybe open settings?
            openSettings()
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Trigger the menu to show
        statusItem?.menu = nil // Clear it so left click works again next time
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Language Switcher Settings"
            window.setContentSize(NSSize(width: 600, height: 400))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false
            
            settingsWindow = window
        }
        
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func updateIcon() {
        // Update icon or text based on current profile
        // For now just use a generic icon, but we could show "A" or "B" etc.
        if let profile = profileManager.getCurrentProfile() {
             statusItem?.button?.title = String(profile.name.prefix(1))
        } else {
             statusItem?.button?.title = "?"
        }
    }
}

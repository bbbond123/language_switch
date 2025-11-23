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
        // No WindowGroup, as this is a menu bar app.
        // However, we need a Settings window that can be opened.
        Settings {
            SettingsView()
        }
    }
}

class MenuBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    private var profileManager = ProfileManager.shared
    
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
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil) // Trigger the menu to show
        statusItem?.menu = nil // Clear it so left click works again next time
    }
    
    @objc private func openSettings() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        
        // Fallback or force activate app to show window
        NSApp.activate(ignoringOtherApps: true)
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

import Foundation
import Carbon

struct InputSource: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let iconURL: URL?
    
    // Helper to get localized name
    static func getName(from source: TISInputSource) -> String {
        let ptr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName)
        return unsafeBitCast(ptr, to: NSString.self) as String
    }
    
    // Helper to get ID
    static func getID(from source: TISInputSource) -> String {
        let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        return unsafeBitCast(ptr, to: NSString.self) as String
    }
    
    // Helper to get Icon URL
    static func getIconURL(from source: TISInputSource) -> URL? {
        let ptr = TISGetInputSourceProperty(source, kTISPropertyIconImageURL)
        if ptr != nil {
            return unsafeBitCast(ptr, to: NSURL.self) as URL
        }
        return nil
    }
}

class InputSourceManager {
    static let shared = InputSourceManager()
    
    private init() {}
    
    // Get all available input sources (enabled + capable of being enabled)
    func getAllAvailableInputSources() -> [InputSource] {
        // kTISPropertyInputSourceIsSelectCapable = true means it's a selectable keyboard layout/input method
        // We want all "Keyboard Input Modes" and "Keyboard Layouts"
        
        guard let sourceList = TISCreateInputSourceList(nil, false).takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        
        var sources: [InputSource] = []
        
        for source in sourceList {
            // Filter for only selectable sources (Keyboards/Input Methods)
            // We check kTISPropertyInputSourceType
            let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType)
            let type = unsafeBitCast(typePtr, to: CFString.self)
            
            if type == kTISTypeKeyboardLayout || type == kTISTypeKeyboardInputMode {
                 // Also check if it is select capable (can be added to the menu)
                let selectCapablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable)
                let selectCapable = unsafeBitCast(selectCapablePtr, to: CFBoolean.self)
                
                if CFBooleanGetValue(selectCapable) {
                    let id = InputSource.getID(from: source)
                    let name = InputSource.getName(from: source)
                    let icon = InputSource.getIconURL(from: source)
                    sources.append(InputSource(id: id, name: name, iconURL: icon))
                }
            }
        }
        
        return sources
    }
    
    // Get currently enabled input sources
    func getEnabledInputSources() -> [InputSource] {
        guard let sourceList = TISCreateInputSourceList(nil, false).takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        
        var sources: [InputSource] = []
        
        for source in sourceList {
            // Check if enabled
            let enabledPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled)
            let isEnabled = unsafeBitCast(enabledPtr, to: CFBoolean.self)
            
            if CFBooleanGetValue(isEnabled) {
                // Double check type to avoid adding internal system inputs
                let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType)
                let type = unsafeBitCast(typePtr, to: CFString.self)
                
                if type == kTISTypeKeyboardLayout || type == kTISTypeKeyboardInputMode {
                     // Also check if it is select capable
                    let selectCapablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable)
                    let selectCapable = unsafeBitCast(selectCapablePtr, to: CFBoolean.self)
                    
                    if CFBooleanGetValue(selectCapable) {
                        let id = InputSource.getID(from: source)
                        let name = InputSource.getName(from: source)
                        let icon = InputSource.getIconURL(from: source)
                        sources.append(InputSource(id: id, name: name, iconURL: icon))
                    }
                }
            }
        }
        return sources
    }
    
    // Enable a specific input source by ID
    func enableInputSource(id: String) {
        guard let source = findInputSource(by: id) else { return }
        TISEnableInputSource(source)
    }
    
    // Disable a specific input source by ID
    func disableInputSource(id: String) {
        guard let source = findInputSource(by: id) else { return }
        TISDisableInputSource(source)
    }
    
    // Apply a profile: Enable all in profile, disable others (except maybe system default?)
    // NOTE: macOS usually requires at least one input source to be enabled.
    // Apply a profile: Enable all in profile, disable others (except maybe system default?)
    // NOTE: macOS usually requires at least one input source to be enabled.
    func applyProfile(inputSourceIDs: [String]) {
        print("Applying profile with IDs: \(inputSourceIDs)")
        
        // 1. Enable all targets first
        for id in inputSourceIDs {
            print("Enabling source: \(id)")
            enableInputSource(id: id)
        }
        
        // 2. Switch to US English (or the first available source)
        // This is CRITICAL: You cannot disable the currently selected input source.
        // So we must switch to one of the new ones before disabling the old ones.
        // User Request: Always switch to English if possible.
        
        var targetSourceToSelect: TISInputSource?
        
        if inputSourceIDs.contains("com.apple.keylayout.US"),
           let usSource = findInputSource(by: "com.apple.keylayout.US") {
            targetSourceToSelect = usSource
        } else if let firstId = inputSourceIDs.first, let source = findInputSource(by: firstId) {
            targetSourceToSelect = source
        }
        
        if let source = targetSourceToSelect {
            print("Selecting source: \(InputSource.getID(from: source))")
            TISSelectInputSource(source)
        }
        
        // 3. Disable ones not in the list
        let enabledSources = getEnabledInputSources()
        print("Currently enabled sources: \(enabledSources.map { $0.id })")
        
        for source in enabledSources {
            if !inputSourceIDs.contains(source.id) {
                print("Disabling source: \(source.id)")
                // Fix: We need to get the actual TISInputSource object, not our struct
                if let tisSource = findInputSource(by: source.id) {
                    let status = TISDisableInputSource(tisSource)
                    if status != noErr {
                        print("Error disabling source \(source.id): \(status)")
                    }
                }
            }
        }
        
        // Double check result
        let finalSources = getEnabledInputSources()
        print("Final enabled sources: \(finalSources.map { $0.id })")
    }
    
    private func findInputSource(by id: String) -> TISInputSource? {
        let properties = [kTISPropertyInputSourceID: id] as CFDictionary
        guard let sourceList = TISCreateInputSourceList(properties, false).takeRetainedValue() as? [TISInputSource],
              let source = sourceList.first else {
            print("Could not find input source with ID: \(id)")
            return nil
        }
        return source
    }
}

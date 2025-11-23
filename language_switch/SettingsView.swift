import SwiftUI

struct SettingsView: View {
    @StateObject private var profileManager = ProfileManager.shared
    @State private var availableInputSources: [InputSource] = []
    @State private var selectedProfileId: UUID?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profiles")) {
                    ForEach($profileManager.profiles) { $profile in
                        NavigationLink(tag: profile.id, selection: $selectedProfileId) {
                            ProfileDetailView(profile: $profile, allSources: availableInputSources, selectedProfileId: $selectedProfileId)
                        } label: {
                            Text(profile.name)
                        }
                    }
                    .onDelete(perform: profileManager.deleteProfile)
                    
                    Button("Add New Profile") {
                        // Default to having US English
                        let newProfile = LanguageProfile(name: "New Profile", inputSourceIDs: ["com.apple.keylayout.US"])
                        profileManager.profiles.append(newProfile)
                        profileManager.saveProfiles()
                        selectedProfileId = newProfile.id
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Language Switcher")
            
            Text("Select a profile to edit")
                .foregroundColor(.secondary)
        }
        .onAppear {
            let sources = InputSourceManager.shared.getAllAvailableInputSources()
            // Sort: US English first, then others alphabetically
            availableInputSources = sources.sorted { a, b in
                if a.id == "com.apple.keylayout.US" { return true }
                if b.id == "com.apple.keylayout.US" { return false }
                return a.name < b.name
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ProfileDetailView: View {
    @Binding var profile: LanguageProfile
    let allSources: [InputSource]
    @State private var showDeleteConfirmation = false
    @Binding var selectedProfileId: UUID?
    
    var body: some View {
        Form {
            TextField("Profile Name", text: $profile.name)
                .onChange(of: profile.name) { _ in
                    ProfileManager.shared.saveProfiles()
                }
            
            Section(header: Text("Input Sources")) {
                List(allSources) { source in
                    HStack {
                        if let iconURL = source.iconURL,
                           let image = NSImage(contentsOf: iconURL) {
                            Image(nsImage: image)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        Text(source.name)
                        Spacer()
                        
                        if source.id == "com.apple.keylayout.US" {
                            // Mandatory source
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            Image(systemName: "checkmark")
                                .foregroundColor(.gray)
                        } else if profile.inputSourceIDs.contains(source.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSource(source)
                    }
                }
                .frame(height: 300)
            }
            
            Section {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete Profile")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .alert(isPresented: $showDeleteConfirmation) {
                    Alert(
                        title: Text("Delete Profile"),
                        message: Text("Are you sure you want to delete '\(profile.name)'? This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteProfile()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .padding()
    }
    
    private func toggleSource(_ source: InputSource) {
        // Prevent removing mandatory US English
        if source.id == "com.apple.keylayout.US" { return }
        
        if let index = profile.inputSourceIDs.firstIndex(of: source.id) {
            profile.inputSourceIDs.remove(at: index)
        } else {
            profile.inputSourceIDs.append(source.id)
        }
        ProfileManager.shared.saveProfiles()
    }
    
    private func deleteProfile() {
        if let index = ProfileManager.shared.profiles.firstIndex(where: { $0.id == profile.id }) {
            ProfileManager.shared.deleteProfile(at: IndexSet(integer: index))
            selectedProfileId = nil // Navigate back
        }
    }
}

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
                            ProfileDetailView(profile: $profile, allSources: availableInputSources)
                        } label: {
                            Text(profile.name)
                        }
                    }
                    .onDelete(perform: profileManager.deleteProfile)
                    
                    Button("Add New Profile") {
                        let newProfile = LanguageProfile(name: "New Profile", inputSourceIDs: [])
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
            availableInputSources = InputSourceManager.shared.getAllAvailableInputSources()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct ProfileDetailView: View {
    @Binding var profile: LanguageProfile
    let allSources: [InputSource]
    
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
                        if profile.inputSourceIDs.contains(source.id) {
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
        }
        .padding()
    }
    
    private func toggleSource(_ source: InputSource) {
        if let index = profile.inputSourceIDs.firstIndex(of: source.id) {
            profile.inputSourceIDs.remove(at: index)
        } else {
            profile.inputSourceIDs.append(source.id)
        }
        ProfileManager.shared.saveProfiles()
    }
}

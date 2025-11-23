import Foundation

struct LanguageProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var inputSourceIDs: [String]
    
    init(id: UUID = UUID(), name: String, inputSourceIDs: [String]) {
        self.id = id
        self.name = name
        self.inputSourceIDs = inputSourceIDs
    }
}

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profiles: [LanguageProfile] = []
    @Published var currentProfileIndex: Int = 0
    
    private let profilesKey = "saved_profiles"
    private let currentProfileIndexKey = "current_profile_index"
    
    private init() {
        loadProfiles()
    }
    
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([LanguageProfile].self, from: data) {
            self.profiles = decoded
        } else {
            // Default profiles if none exist
            // Note: These IDs are examples, actual IDs depend on the system
            // We will let the user configure them, or try to detect defaults later.
            self.profiles = []
        }
        
        self.currentProfileIndex = UserDefaults.standard.integer(forKey: currentProfileIndexKey)
    }
    
    func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
    }
    
    func addProfile(name: String, inputSourceIDs: [String]) {
        let newProfile = LanguageProfile(name: name, inputSourceIDs: inputSourceIDs)
        profiles.append(newProfile)
        saveProfiles()
    }
    
    func updateProfile(_ profile: LanguageProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            saveProfiles()
        }
    }
    
    func deleteProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        saveProfiles()
        
        // Adjust current index if needed
        if currentProfileIndex >= profiles.count {
            currentProfileIndex = max(0, profiles.count - 1)
        }
    }
    
    func cycleToNextProfile() -> LanguageProfile? {
        guard !profiles.isEmpty else { return nil }
        
        currentProfileIndex = (currentProfileIndex + 1) % profiles.count
        UserDefaults.standard.set(currentProfileIndex, forKey: currentProfileIndexKey)
        
        return profiles[currentProfileIndex]
    }
    
    func getCurrentProfile() -> LanguageProfile? {
        guard !profiles.isEmpty, profiles.indices.contains(currentProfileIndex) else { return nil }
        return profiles[currentProfileIndex]
    }
}

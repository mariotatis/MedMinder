import Foundation
import Combine

class ProfileListViewModel: ObservableObject {
    @Published var profiles: [Profile] = []
    
    let profileUseCases: ProfileUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(profileUseCases: ProfileUseCases) {
        self.profileUseCases = profileUseCases
        fetchProfiles()
    }
    
    func fetchProfiles() {
        profileUseCases.getProfiles()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] newProfiles in
                guard let self = self else { return }
                
                // Update existing profiles or add new ones to preserve navigation state
                var updatedProfiles = self.profiles
                
                // Update existing profiles
                for newProfile in newProfiles {
                    if let index = updatedProfiles.firstIndex(where: { $0.id == newProfile.id }) {
                        updatedProfiles[index] = newProfile
                    } else {
                        updatedProfiles.append(newProfile)
                    }
                }
                
                // Remove profiles that no longer exist
                updatedProfiles.removeAll { profile in
                    !newProfiles.contains(where: { $0.id == profile.id })
                }
                
                self.profiles = updatedProfiles
            })
            .store(in: &cancellables)
    }
}

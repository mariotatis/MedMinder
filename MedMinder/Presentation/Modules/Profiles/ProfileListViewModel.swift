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
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profiles in
                self?.profiles = profiles
            })
            .store(in: &cancellables)
    }
}

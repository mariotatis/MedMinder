import Foundation
import Combine

class ProfileUseCases {
    private let repository: ProfileRepository
    private let treatmentRepository: TreatmentRepository
    
    init(repository: ProfileRepository, treatmentRepository: TreatmentRepository) {
        self.repository = repository
        self.treatmentRepository = treatmentRepository
    }
    
    func getProfiles() -> AnyPublisher<[Profile], Error> {
        return repository.getProfiles()
    }
    
    func addProfile(_ profile: Profile) -> AnyPublisher<Void, Error> {
        return repository.addProfile(profile)
    }
    
    func updateProfile(_ profile: Profile) -> AnyPublisher<Void, Error> {
        return repository.updateProfile(profile)
    }
    
    func deleteProfile(id: UUID) -> AnyPublisher<Void, Error> {
        treatmentRepository.getTreatments()
            .flatMap { [weak self] treatments -> AnyPublisher<Void, Error> in
                guard let self = self else { return Fail(error: NSError(domain: "SelfDeallocated", code: -1, userInfo: nil)).eraseToAnyPublisher() }
                
                let treatmentsToUpdate = treatments.filter { $0.profileId == id }
                
                if treatmentsToUpdate.isEmpty {
                    return self.repository.deleteProfile(id: id)
                }
                
                let updates = treatmentsToUpdate.map { treatment -> AnyPublisher<Void, Error> in
                    var updatedTreatment = treatment
                    updatedTreatment.profileId = nil
                    return self.treatmentRepository.updateTreatment(updatedTreatment)
                }
                
                return Publishers.MergeMany(updates)
                    .collect()
                    .flatMap { _ in
                        self.repository.deleteProfile(id: id)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

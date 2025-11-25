import Foundation
import Combine

class TreatmentUseCases {
    private let repository: TreatmentRepository
    
    init(repository: TreatmentRepository) {
        self.repository = repository
    }
    
    func getTreatments() -> AnyPublisher<[Treatment], Error> {
        return repository.getTreatments()
    }
    
    func addTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error> {
        return repository.addTreatment(treatment)
    }
    
    func updateTreatment(_ treatment: Treatment) -> AnyPublisher<Void, Error> {
        return repository.updateTreatment(treatment)
    }
    
    func deleteTreatment(id: UUID) -> AnyPublisher<Void, Error> {
        return repository.deleteTreatment(id: id)
    }
}

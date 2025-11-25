import Foundation
import Combine

class MedicationUseCases {
    private let repository: MedicationRepository
    
    init(repository: MedicationRepository) {
        self.repository = repository
    }
    
    func getMedications() -> AnyPublisher<[Medication], Error> {
        return repository.getMedications()
    }
    
    func addMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        return repository.addMedication(medication)
    }
    
    func updateMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        return repository.updateMedication(medication)
    }
    
    func deleteMedication(id: UUID) -> AnyPublisher<Void, Error> {
        return repository.deleteMedication(id: id)
    }
    
    func getDoseLogs() -> AnyPublisher<[DoseLog], Error> {
        return repository.getDoseLogs()
    }
    
    func logDose(_ log: DoseLog) -> AnyPublisher<Void, Error> {
        return repository.logDose(log)
    }
    
    // Helper to get medications for a specific date (next 24h logic can be here or in ViewModel)
    // For now, we'll keep it simple and filter in ViewModel or add a specific UseCase later.
}

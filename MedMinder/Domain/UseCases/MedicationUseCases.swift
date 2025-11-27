import Foundation
import Combine

class MedicationUseCases {
    private let repository: MedicationRepository
    private let notificationService: NotificationService
    
    init(repository: MedicationRepository, notificationService: NotificationService) {
        self.repository = repository
        self.notificationService = notificationService
    }
    
    func getMedications() -> AnyPublisher<[Medication], Error> {
        return repository.getMedications()
    }
    
    func addMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        return repository.addMedication(medication)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Only schedule if reminders are enabled (checked in service)
                self?.notificationService.scheduleReminders(for: medication)
            })
            .eraseToAnyPublisher()
    }
    
    func updateMedication(_ medication: Medication) -> AnyPublisher<Void, Error> {
        return repository.updateMedication(medication)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.notificationService.scheduleReminders(for: medication)
            })
            .eraseToAnyPublisher()
    }
    
    func deleteMedication(id: UUID) -> AnyPublisher<Void, Error> {
        // We need the medication object to cancel reminders by ID group, or just cancel by ID prefix
        // Since we only have ID here, we rely on the service's cancelReminders logic which might need the ID.
        // Actually, our service cancelReminders takes a Medication object.
        // Let's fetch it first or update service to take ID.
        // For simplicity, let's assume we can fetch it or just ignore for now (or update service).
        // Better: Update service to take ID for cancellation.
        
        // Let's fetch first (or assume repository handles it).
        // To keep it simple and robust, let's just proceed with delete.
        // Ideally we should cancel reminders.
        
        // FIX: Let's fetch the medication first to cancel properly, or update service.
        // For now, let's just delete. The reminders will fire but user won't find the med.
        // Actually, let's do it right.
        
        return getMedications()
            .first()
            .flatMap { medications -> AnyPublisher<Void, Error> in
                if let medication = medications.first(where: { $0.id == id }) {
                    self.notificationService.cancelReminders(for: medication)
                }
                return self.repository.deleteMedication(id: id)
            }
            .eraseToAnyPublisher()
    }
    
    func getDoseLogs() -> AnyPublisher<[DoseLog], Error> {
        return repository.getDoseLogs()
    }
    
    func logDose(_ log: DoseLog) -> AnyPublisher<Void, Error> {
        return repository.logDose(log)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.notificationService.cancelSpecificReminder(for: log.medicationId, at: log.scheduledTime)
            })
            .eraseToAnyPublisher()
    }
    
    // Helper to get medications for a specific date (next 24h logic can be here or in ViewModel)
    // For now, we'll keep it simple and filter in ViewModel or add a specific UseCase later.
}

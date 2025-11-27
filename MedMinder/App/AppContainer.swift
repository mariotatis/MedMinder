import Foundation

class AppContainer: ObservableObject {
    // Repositories
    let profileRepository: ProfileRepository
    let treatmentRepository: TreatmentRepository
    let medicationRepository: MedicationRepository
    
    // Use Cases
    let profileUseCases: ProfileUseCases
    let treatmentUseCases: TreatmentUseCases
    let medicationUseCases: MedicationUseCases
    let notificationService: NotificationService
    
    init() {
        // Initialize Repositories
        self.profileRepository = LocalProfileRepository()
        self.treatmentRepository = LocalTreatmentRepository()
        self.medicationRepository = LocalMedicationRepository()
        
        // Initialize Use Cases
        self.notificationService = NotificationService.shared
        self.profileUseCases = ProfileUseCases(repository: profileRepository, treatmentRepository: treatmentRepository)
        self.treatmentUseCases = TreatmentUseCases(repository: treatmentRepository)
        self.medicationUseCases = MedicationUseCases(repository: medicationRepository, notificationService: notificationService)
    }
    
    func syncReminders() {
        // Only sync if reminders are enabled
        if UserDefaults.standard.bool(forKey: "areRemindersEnabled") {
            _ = medicationUseCases.getMedications()
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] medications in
                    self?.notificationService.rescheduleAll(medications: medications)
                })
        }
    }
}

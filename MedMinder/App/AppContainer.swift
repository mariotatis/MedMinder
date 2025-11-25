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
    
    init() {
        // Initialize Repositories
        self.profileRepository = LocalProfileRepository()
        self.treatmentRepository = LocalTreatmentRepository()
        self.medicationRepository = LocalMedicationRepository()
        
        // Initialize Use Cases
        self.profileUseCases = ProfileUseCases(repository: profileRepository, treatmentRepository: treatmentRepository)
        self.treatmentUseCases = TreatmentUseCases(repository: treatmentRepository)
        self.medicationUseCases = MedicationUseCases(repository: medicationRepository)
    }
}

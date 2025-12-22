import Foundation
import Combine

class TreatmentListViewModel: ObservableObject {
    @Published var treatments: [Treatment] = []
    @Published var profiles: [Profile] = []
    @Published var medications: [Medication] = []
    @Published var doseLogs: [DoseLog] = []
    
    private let treatmentUseCases: TreatmentUseCases
    private let profileUseCases: ProfileUseCases
    private let medicationUseCases: MedicationUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases, medicationUseCases: MedicationUseCases) {
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        self.medicationUseCases = medicationUseCases
        fetchTreatments()
    }
    
    func fetchTreatments() {
        Publishers.Zip4(
            treatmentUseCases.getTreatments(),
            profileUseCases.getProfiles(),
            medicationUseCases.getMedications(),
            medicationUseCases.getDoseLogs()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] treatments, profiles, medications, logs in
            self?.treatments = treatments
            self?.profiles = profiles
            self?.medications = medications
            self?.doseLogs = logs
        })
        .store(in: &cancellables)
    }
    
    func getProfile(for profileId: UUID?) -> Profile? {
        guard let id = profileId else { return nil }
        return profiles.first(where: { $0.id == id })
    }
    
    func getProfileName(for treatment: Treatment) -> String {
        return profiles.first(where: { $0.id == treatment.profileId })?.name ?? "Unknown"
    }
    
    func getMedicationCount(for treatmentId: UUID) -> Int {
        return medications.filter { $0.treatmentId == treatmentId }.count
    }
    
    func isTreatmentCompleted(_ treatmentId: UUID) -> Bool {
        let treatmentMeds = medications.filter { $0.treatmentId == treatmentId }
        guard !treatmentMeds.isEmpty else { return false }
        
        let result = TreatmentProgressCalculator.calculateTreatmentProgress(
            medications: treatmentMeds,
            allLogs: doseLogs
        )
        return result.isCompleted
    }
    
    func getTreatmentProgress(for treatmentId: UUID) -> Double? {
        let treatmentMeds = medications.filter { $0.treatmentId == treatmentId }
        guard !treatmentMeds.isEmpty else { return 0 }
        
        let result = TreatmentProgressCalculator.calculateTreatmentProgress(
            medications: treatmentMeds,
            allLogs: doseLogs
        )
        return result.progress
    }
}

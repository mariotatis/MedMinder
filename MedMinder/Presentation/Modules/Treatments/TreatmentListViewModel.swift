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
        guard let treatment = treatments.first(where: { $0.id == treatmentId }) else { return false }
        
        let treatmentMeds = medications.filter { $0.treatmentId == treatmentId }
        guard !treatmentMeds.isEmpty else { return false }
        
        let now = Date()
        
        // Get all medication IDs for this treatment
        let treatmentMedicationIds = Set(treatmentMeds.map { $0.id })
        
        // Count dose logs for this treatment (taken or skipped only)
        let treatmentLogs = doseLogs.filter { log in
            treatmentMedicationIds.contains(log.medicationId) &&
            (log.status == .taken || log.status == .skipped)
        }
        
        // Check if all medications are past their end date
        var allPastEndDate = true
        var hasAnyLogs = !treatmentLogs.isEmpty
        
        for med in treatmentMeds {
            let durationDays = med.durationDays
            let frequencyHours = med.frequencyHours
            
            if durationDays <= 0 || frequencyHours <= 0 {
                return false
            }
            
            let endDate = Calendar.current.date(byAdding: .day, value: durationDays, to: med.initialTime) ?? now
            
            if now < endDate {
                allPastEndDate = false
            }
        }
        
        // Treatment is complete if:
        // 1. All medications are past their end date
        // 2. There is at least one logged dose (taken or skipped)
        return allPastEndDate && hasAnyLogs
    }
}

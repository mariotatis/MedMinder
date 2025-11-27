import Foundation
import Combine

class ProfileDetailViewModel: ObservableObject {
    @Published var profile: Profile
    @Published var treatments: [Treatment] = []
    @Published var medications: [Medication] = []
    @Published var doseLogs: [DoseLog] = []
    @Published var shouldDismiss: Bool = false
    
    let treatmentUseCases: TreatmentUseCases
    let profileUseCases: ProfileUseCases
    let medicationUseCases: MedicationUseCases
    
    private var cancellables = Set<AnyCancellable>()
    private var onDelete: (() -> Void)?
    private var onUpdate: (() -> Void)?
    
    init(profile: Profile, treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases, medicationUseCases: MedicationUseCases, onDelete: (() -> Void)? = nil, onUpdate: (() -> Void)? = nil) {
        self.profile = profile
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        self.medicationUseCases = medicationUseCases
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        
        fetchTreatments()
        fetchMedications()
        fetchDoseLogs()
    }
    
    func fetchTreatments() {
        treatmentUseCases.getTreatments()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] allTreatments in
                guard let self = self else { return }
                self.treatments = allTreatments.filter { $0.profileId == self.profile.id }
            })
            .store(in: &cancellables)
    }
    
    func fetchMedications() {
        medicationUseCases.getMedications()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] allMedications in
                self?.medications = allMedications
            })
            .store(in: &cancellables)
    }
    
    func fetchDoseLogs() {
        medicationUseCases.getDoseLogs()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] logs in
                self?.doseLogs = logs
            })
            .store(in: &cancellables)
    }
    
    func refreshProfile() {
        profileUseCases.getProfiles()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profiles in
                guard let self = self else { return }
                if let updatedProfile = profiles.first(where: { $0.id == self.profile.id }) {
                    self.profile = updatedProfile
                    // Notify parent that profile was updated
                    self.onUpdate?()
                    // Also refresh treatments in case profile association changed (though unlikely from here)
                    self.fetchTreatments()
                } else {
                    // Profile was deleted
                    self.onDelete?()
                    self.shouldDismiss = true
                }
            })
            .store(in: &cancellables)
    }
    
    func getMedicationCount(for treatmentId: UUID) -> Int {
        return medications.filter { $0.treatmentId == treatmentId }.count
    }
    
    func isTreatmentCompleted(_ treatmentId: UUID) -> Bool {
        // Simple logic for now, can be expanded based on requirements
        guard let treatment = treatments.first(where: { $0.id == treatmentId }) else { return false }
        
        let treatmentMeds = medications.filter { $0.treatmentId == treatmentId }
        guard !treatmentMeds.isEmpty else { return false }
        
        var allMedsCompleted = true
        
        for med in treatmentMeds {
            let durationDays = med.durationDays
            let frequencyHours = med.frequencyHours
            
            if durationDays <= 0 || frequencyHours <= 0 {
                allMedsCompleted = false
                break
            }
            
            let calendar = Calendar.current
            let endDate = calendar.date(byAdding: .day, value: durationDays, to: med.initialTime) ?? Date()
            let frequencySeconds = Double(frequencyHours) * 3600
            
            var expectedDoses: [Date] = []
            var currentTime = med.initialTime
            
            while currentTime <= endDate {
                expectedDoses.append(currentTime)
                currentTime += frequencySeconds
            }
            
            let medLogs = doseLogs.filter { $0.medicationId == med.id && ($0.status == .taken || $0.status == .skipped) }
            
            if medLogs.count < expectedDoses.count {
                allMedsCompleted = false
                break
            }
        }
        
        return allMedsCompleted
    }
}

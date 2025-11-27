import Foundation
import Combine

class AddTreatmentViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var selectedProfileId: UUID?
    @Published var startDate: Date = Date()
    @Published var profiles: [Profile] = []
    @Published var medications: [Medication] = []
    @Published var showAddMedication: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showDeleteConfirmation: Bool = false
    @Published var doseLogs: [DoseLog] = []
    
    let treatmentUseCases: TreatmentUseCases
    let profileUseCases: ProfileUseCases
    let medicationUseCases: MedicationUseCases
    
    private var cancellables = Set<AnyCancellable>()
    var editingTreatmentId: UUID?
    
    var isEditing: Bool {
        return editingTreatmentId != nil
    }
    
    init(treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases, medicationUseCases: MedicationUseCases, treatment: Treatment? = nil) {
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        self.medicationUseCases = medicationUseCases
        
        if let treatment = treatment {
            self.name = treatment.name
            self.selectedProfileId = treatment.profileId
            self.startDate = treatment.startDate
            self.editingTreatmentId = treatment.id
            fetchMedications(for: treatment.id)
        }
        
        fetchProfiles()
        fetchDoseLogs()
    }
    
    func fetchMedications(for treatmentId: UUID) {
        medicationUseCases.getMedications()
            .map { meds in
                meds.filter { $0.treatmentId == treatmentId }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] meds in
                self?.medications = meds
                self?.originalMedicationIds = Set(meds.map { $0.id })
            })
            .store(in: &cancellables)
    }
    
    func fetchProfiles() {
        profileUseCases.getProfiles()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profiles in
                self?.profiles = profiles
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
    
    var isCompleted: Bool {
        guard let treatmentId = editingTreatmentId else { return false }
        guard !medications.isEmpty else { return false }
        
        let now = Date()
        
        // Get medication IDs
        let medicationIds = Set(medications.map { $0.id })
        
        // Count logged doses (taken or skipped)
        let loggedDoses = doseLogs.filter { log in
            medicationIds.contains(log.medicationId) &&
            (log.status == .taken || log.status == .skipped)
        }
        
        // Complete if count of logged doses matches expected doses
        // (Robust count-based logic)
        var allMedsCompleted = true
        
        for med in medications {
            let durationDays = med.durationDays
            let frequencyHours = med.frequencyHours
            
            if durationDays <= 0 || frequencyHours <= 0 {
                allMedsCompleted = false
                break
            }
            
            let calendar = Calendar.current
            let endDate = calendar.date(byAdding: .day, value: durationDays, to: med.initialTime) ?? now
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
    
    private var originalMedicationIds: Set<UUID> = []
    private var deletedMedicationIds: Set<UUID> = []
    
    @Published var editingMedication: Medication?
    
    func addMedication(_ medication: Medication) {
        if let treatmentId = editingTreatmentId {
            // Auto-save for existing treatment
            var newMed = medication
            newMed.treatmentId = treatmentId
            
            medicationUseCases.addMedication(newMed)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.fetchMedications(for: treatmentId)
                })
                .store(in: &cancellables)
        } else {
            medications.append(medication)
        }
    }
    
    func updateMedication(_ medication: Medication) {
        if let treatmentId = editingTreatmentId {
            // Auto-save for existing treatment
            var newMed = medication
            newMed.treatmentId = treatmentId
            
            medicationUseCases.updateMedication(newMed)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.fetchMedications(for: treatmentId)
                })
                .store(in: &cancellables)
        } else {
            if let index = medications.firstIndex(where: { $0.id == medication.id }) {
                medications[index] = medication
            } else {
                // Fallback if not found (shouldn't happen if editing)
                medications.append(medication)
            }
        }
    }
    
    func saveTreatment() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a treatment name."
            showError = true
            return
        }
        
        let profileId = selectedProfileId
        
        if let id = editingTreatmentId {
            // Update existing treatment
            // Medications are auto-saved in this mode, so we only update the treatment details
            let treatment = Treatment(id: id, name: name, startDate: startDate, endDate: nil, profileId: profileId)
            treatmentUseCases.updateTreatment(treatment)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    // Don't dismiss here for edit mode, let the view handle it (to go back to details)
                    // self?.shouldDismiss = true 
                })
                .store(in: &cancellables)
        } else {
            // Create new treatment
            let treatmentId = UUID()
            let treatment = Treatment(id: treatmentId, name: name, startDate: startDate, endDate: nil, profileId: profileId)
            
            treatmentUseCases.addTreatment(treatment)
                .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                    guard let self = self, !self.medications.isEmpty else {
                        return Result.Publisher(()).eraseToAnyPublisher()
                    }
                    
                    // Save all medications
                    let savePublishers = self.medications.map { med -> AnyPublisher<Void, Error> in
                        var newMed = med
                        newMed = Medication(
                            id: med.id,
                            name: med.name,
                            dosage: med.dosage,
                            frequencyHours: med.frequencyHours,
                            durationDays: med.durationDays,
                            type: med.type,
                            initialTime: med.initialTime,
                            color: med.color,
                            treatmentId: treatmentId // Link to the new treatment
                        )
                        return self.medicationUseCases.addMedication(newMed)
                    }
                    
                    return Publishers.MergeMany(savePublishers)
                        .collect()
                        .map { _ in () }
                        .eraseToAnyPublisher()
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.shouldDismiss = true
                })
                .store(in: &cancellables)
        }
    }
    
    func deleteTreatment() {
        guard let id = editingTreatmentId else { return }
        treatmentUseCases.deleteTreatment(id: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?.shouldDismiss = true
            })
            .store(in: &cancellables)
    }
    
    func deleteMedication(_ medication: Medication) {
        if let treatmentId = editingTreatmentId {
            // Auto-delete for existing treatment
            medicationUseCases.deleteMedication(id: medication.id)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.fetchMedications(for: treatmentId)
                })
                .store(in: &cancellables)
        } else {
            if let index = medications.firstIndex(where: { $0.id == medication.id }) {
                medications.remove(at: index)
                // If it was an existing medication, mark for deletion from repo
                if originalMedicationIds.contains(medication.id) {
                    deletedMedicationIds.insert(medication.id)
                }
            }
        }
    }
}

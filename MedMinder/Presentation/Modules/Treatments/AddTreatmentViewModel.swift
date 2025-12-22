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
    var preselectedProfileId: UUID?
    
    var isEditing: Bool {
        return editingTreatmentId != nil
    }
    
    var computedProgress: Double? {
        guard !medications.isEmpty else { return 0 }
        
        let result = TreatmentProgressCalculator.calculateTreatmentProgress(
            medications: medications,
            allLogs: doseLogs
        )
        return result.progress
    }
    
    init(treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases, medicationUseCases: MedicationUseCases, treatment: Treatment? = nil, preselectedProfileId: UUID? = nil) {
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        self.medicationUseCases = medicationUseCases
        self.preselectedProfileId = preselectedProfileId
        
        if let treatment = treatment {
            self.name = treatment.name
            self.selectedProfileId = treatment.profileId
            self.startDate = treatment.startDate
            self.editingTreatmentId = treatment.id
            fetchMedications(for: treatment.id)
        } else if let preselectedId = preselectedProfileId {
            self.selectedProfileId = preselectedId
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
        guard !medications.isEmpty else { return false }
        
        let result = TreatmentProgressCalculator.calculateTreatmentProgress(
            medications: medications,
            allLogs: doseLogs
        )
        return result.isCompleted
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
            // Silently save treatment first, then add medication
            autoSaveTreatment(with: medication)
        }
    }
    
    private func autoSaveTreatment(with lastMedication: Medication) {
        let treatmentId = UUID()
        let treatmentName = name.isEmpty ? "New Treatment" : name
        if name.isEmpty { name = treatmentName }
        
        let treatment = Treatment(id: treatmentId, name: treatmentName, startDate: startDate, endDate: nil, profileId: selectedProfileId)
        
        treatmentUseCases.addTreatment(treatment)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "AddTreatmentViewModel", code: -1)).eraseToAnyPublisher()
                }
                
                // Set the ID so view switches to edit mode
                self.editingTreatmentId = treatmentId
                
                // Save ALL medications currently in the local list + the new one
                var allMedsToSave = self.medications
                allMedsToSave.append(lastMedication)
                
                let publishers = allMedsToSave.map { med -> AnyPublisher<Void, Error> in
                    var m = med
                    m.treatmentId = treatmentId
                    return self.medicationUseCases.addMedication(m)
                }
                
                return Publishers.MergeMany(publishers)
                    .collect()
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchMedications(for: treatmentId)
                self?.fetchDoseLogs()
            })
            .store(in: &cancellables)
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
            // Update existing treatment details
            let treatment = Treatment(id: id, name: name, startDate: startDate, endDate: nil, profileId: profileId)
            treatmentUseCases.updateTreatment(treatment)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    // In edit mode, we don't necessarily dismiss, 
                    // but the Button in AddTreatmentView might expect it or it might just stay.
                    // The user said "hide the treatment Save button" which happens once isEditing is true.
                })
                .store(in: &cancellables)
        } else {
            // Create new treatment manually
            let treatmentId = UUID()
            let treatment = Treatment(id: treatmentId, name: name, startDate: startDate, endDate: nil, profileId: profileId)
            
            treatmentUseCases.addTreatment(treatment)
                .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                    guard let self = self, !self.medications.isEmpty else {
                        return Result.Publisher(()).eraseToAnyPublisher()
                    }
                    
                    // Save all medications that were added locally
                    let savePublishers = self.medications.map { med -> AnyPublisher<Void, Error> in
                        var newMed = med
                        newMed.treatmentId = treatmentId
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

    
    func getMedicationStatus(medication: Medication) -> (isCompleted: Bool, upcomingCount: Int, progress: Double) {
        let result = TreatmentProgressCalculator.calculateProgress(for: medication, logs: doseLogs)
        return (result.isCompleted, max(0, result.totalExpectedDoses - result.loggedDosesCount), result.progress)
    }
}

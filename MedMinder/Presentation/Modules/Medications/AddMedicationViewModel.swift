import Foundation
import Combine
import SwiftUI

class AddMedicationViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var dosage: String = ""
    @Published var frequencyHours: String = ""
    @Published var durationDays: String = ""
    @Published var selectedType: MedicationType = .pills
    @Published var initialTime: Date = Date()
    @Published var selectedColor: MedicationColor = MedicationColor.allCases.randomElement() ?? .red
    @Published var shouldDismiss: Bool = false
    
    let treatmentId: UUID
    private let medicationUseCases: MedicationUseCases?
    var onSave: ((Medication) -> Void)?
    var onDelete: ((Medication) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    private var editingMedicationId: UUID?
    
    // Init for existing treatment (saves to repo)
    init(treatmentId: UUID, medicationUseCases: MedicationUseCases, medication: Medication? = nil) {
        self.treatmentId = treatmentId
        self.medicationUseCases = medicationUseCases
        self.onSave = nil
        self.onDelete = nil
        if let medication = medication {
            configure(with: medication)
        }
    }
    
    // Init for new treatment flow (returns object)
    init(treatmentId: UUID, medication: Medication? = nil, onSave: @escaping (Medication) -> Void, onDelete: ((Medication) -> Void)? = nil) {
        self.treatmentId = treatmentId
        self.medicationUseCases = nil
        self.onSave = onSave
        self.onDelete = onDelete
        if let medication = medication {
            configure(with: medication)
        }
    }
    
    private func configure(with medication: Medication) {
        self.editingMedicationId = medication.id
        self.name = medication.name
        self.dosage = medication.dosage
        self.frequencyHours = String(medication.frequencyHours)
        self.durationDays = String(medication.durationDays)
        self.selectedType = medication.type
        self.initialTime = medication.initialTime
        self.selectedColor = medication.color
    }
    
    var isEditing: Bool {
        return editingMedicationId != nil
    }
    
    func saveMedication() {
        guard !name.isEmpty,
              !dosage.isEmpty,
              let freq = Int(frequencyHours),
              let days = Int(durationDays) else { return }
        
        let medication = Medication(
            id: editingMedicationId ?? UUID(),
            name: name,
            dosage: dosage,
            frequencyHours: freq,
            durationDays: days,
            type: selectedType,
            initialTime: initialTime,
            color: selectedColor,
            treatmentId: treatmentId
        )
        
        if let onSave = onSave {
            onSave(medication)
            shouldDismiss = true
        } else if let useCases = medicationUseCases {
            let publisher: AnyPublisher<Void, Error>
            
            if isEditing {
                publisher = useCases.updateMedication(medication)
            } else {
                publisher = useCases.addMedication(medication)
            }
            
            publisher
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.shouldDismiss = true
                })
                .store(in: &cancellables)
        }
    }
    
    func deleteMedication() {
        guard let id = editingMedicationId else { return }
        
        // Reconstruct medication object for callback (simplified, ID is what matters)
        let medication = Medication(
            id: id,
            name: name,
            dosage: dosage,
            frequencyHours: Int(frequencyHours) ?? 0,
            durationDays: Int(durationDays) ?? 0,
            type: selectedType,
            initialTime: initialTime,
            color: selectedColor,
            treatmentId: treatmentId
        )
        
        if let onDelete = onDelete {
            onDelete(medication)
            shouldDismiss = true
        } else if let useCases = medicationUseCases {
            useCases.deleteMedication(id: id)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                    self?.shouldDismiss = true
                })
                .store(in: &cancellables)
        }
    }
}

import Foundation
import Combine

class TreatmentDosageRegistryViewModel: ObservableObject {
    @Published var doseLogs: [DoseLogWithMedication] = []
    
    private let treatmentId: UUID
    private let medicationUseCases: MedicationUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(treatmentId: UUID, medicationUseCases: MedicationUseCases) {
        self.treatmentId = treatmentId
        self.medicationUseCases = medicationUseCases
    }
    
    func fetchDoseLogs() {
        // Get all medications and dose logs
        Publishers.Zip(
            medicationUseCases.getMedications(),
            medicationUseCases.getDoseLogs()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Error fetching dose logs: \(error)")
            }
        }, receiveValue: { [weak self] (medications, doseLogs) in
            guard let self = self else { return }
            
            // Filter medications for this treatment
            let treatmentMedications = medications.filter { $0.treatmentId == self.treatmentId }
            let treatmentMedicationIds = Set(treatmentMedications.map { $0.id })
            
            // Get existing logs for these medications (all statuses)
            let existingLogs = doseLogs.filter { log in
                treatmentMedicationIds.contains(log.medicationId)
            }
            
            // Generate upcoming doses for medications that haven't ended yet
            var allDoses: [DoseLog] = existingLogs
            let now = Date()
            let calendar = Calendar.current
            
            for medication in treatmentMedications {
                // Calculate end date
                let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) ?? now
                
                // Only generate upcoming doses if medication hasn't ended
                if now < endDate {
                    // Get existing scheduled times for this medication
                    let existingScheduledTimes = Set(existingLogs
                        .filter { $0.medicationId == medication.id }
                        .map { calendar.startOfDay(for: $0.scheduledTime).addingTimeInterval($0.scheduledTime.timeIntervalSince(calendar.startOfDay(for: $0.scheduledTime))) }
                    )
                    
                    // Generate doses from now until end date
                    var currentTime = medication.initialTime
                    let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
                    
                    while currentTime <= endDate {
                        // Only create if this scheduled time doesn't already have a log
                        if !existingScheduledTimes.contains(currentTime) && currentTime >= now {
                            let upcomingDose = DoseLog(
                                id: UUID(),
                                medicationId: medication.id,
                                scheduledTime: currentTime,
                                takenTime: nil,
                                status: .pending
                            )
                            allDoses.append(upcomingDose)
                        }
                        currentTime = currentTime.addingTimeInterval(frequencyInterval)
                    }
                }
            }
            
            // Combine logs with medication info
            let logsWithMedication: [DoseLogWithMedication] = allDoses.compactMap { log in
                guard let medication = treatmentMedications.first(where: { $0.id == log.medicationId }) else {
                    return nil
                }
                return DoseLogWithMedication(doseLog: log, medication: medication)
            }
            
            // Sort chronologically (oldest first, upcoming at bottom)
            self.doseLogs = logsWithMedication.sorted { $0.doseLog.scheduledTime < $1.doseLog.scheduledTime }
        })
        .store(in: &cancellables)
    }
}

struct DoseLogWithMedication: Identifiable {
    let id = UUID()
    let doseLog: DoseLog
    let medication: Medication
}

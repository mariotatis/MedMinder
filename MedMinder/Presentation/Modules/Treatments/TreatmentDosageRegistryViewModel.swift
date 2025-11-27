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
    
    @Published var isCompleted: Bool = false
    
    private func checkCompletion(medications: [Medication], doseLogs: [DoseLog]) {
        var allMedsCompleted = true
        
        for med in medications {
            // 1. Calculate expected doses
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
            
            // Generate all scheduled times
            while currentTime <= endDate {
                expectedDoses.append(currentTime)
                currentTime += frequencySeconds
            }
            
            // 2. Check if the number of logged doses (taken/skipped) matches or exceeds the expected count
            let medLogs = doseLogs.filter { $0.medicationId == med.id && ($0.status == .taken || $0.status == .skipped) }
            
            let isMedComplete = medLogs.count >= expectedDoses.count
            
            if !isMedComplete {
                allMedsCompleted = false
                break
            }
        }
        
        self.isCompleted = allMedsCompleted
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
            
            // Check completion status
            self.checkCompletion(medications: treatmentMedications, doseLogs: existingLogs)
        })
        .store(in: &cancellables)
    }
}

struct DoseLogWithMedication: Identifiable {
    let id = UUID()
    let doseLog: DoseLog
    let medication: Medication
}

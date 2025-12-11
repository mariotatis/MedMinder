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
    @Published var selectedSegment: Int = 0 // 0 = Upcoming, 1 = History (default to Upcoming)
    
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
    
    var missedDoseCount: Int {
        doseLogs.filter { $0.doseLog.status == .pending && $0.doseLog.scheduledTime < Date() }.count
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
                print("[TreatmentDosageRegistry] Generating doses for medication: \(medication.name)")
                
                // Calculate end date
                let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) ?? now
                
                // Get existing scheduled times for this medication
                let existingScheduledTimes = Set(existingLogs
                    .filter { $0.medicationId == medication.id }
                    .map { log in
                        // Normalize to minute precision for comparison
                        calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: log.scheduledTime))!
                    }
                )
                
                // Generate ALL doses from initial time to end date (including past missed doses)
                // Normalize to zero seconds
                var currentTime = calendar.date(bySetting: .second, value: 0, of: medication.initialTime) ?? medication.initialTime
                let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
                
                var expectedCount = 0
                var missedCount = 0
                
                while currentTime <= endDate {
                    expectedCount += 1
                    
                    // Normalize current time for comparison
                    let normalizedCurrentTime = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentTime))!
                    
                    // Only create if this scheduled time doesn't already have a log
                    if !existingScheduledTimes.contains(normalizedCurrentTime) {
                        let isPast = currentTime < now
                        if isPast {
                            missedCount += 1
                            print("[TreatmentDosageRegistry] Missed dose at: \(currentTime)")
                        }
                        
                        let pendingDose = DoseLog(
                            id: UUID(),
                            medicationId: medication.id,
                            scheduledTime: currentTime,
                            takenTime: nil,
                            status: .pending
                        )
                        allDoses.append(pendingDose)
                    }
                    currentTime = currentTime.addingTimeInterval(frequencyInterval)
                }
                
                print("[TreatmentDosageRegistry] Expected: \(expectedCount), Missed: \(missedCount)")
            }
            
            // Combine logs with medication info
            let logsWithMedication: [DoseLogWithMedication] = allDoses.compactMap { log in
                guard let medication = treatmentMedications.first(where: { $0.id == log.medicationId }) else {
                    return nil
                }
                return DoseLogWithMedication(doseLog: log, medication: medication)
            }
            
            // Sort chronologically (newest first) using takenTime for taken doses, scheduledTime for others
            self.doseLogs = logsWithMedication.sorted { log1, log2 in
                let time1 = log1.doseLog.takenTime ?? log1.doseLog.scheduledTime
                let time2 = log2.doseLog.takenTime ?? log2.doseLog.scheduledTime
                return time1 > time2
            }
            
            // Check completion status
            self.checkCompletion(medications: treatmentMedications, doseLogs: existingLogs)
        })
        .store(in: &cancellables)
    }
    
    // MARK: - Mark Specific Doses
    
    func markDoseAsTaken(medicationId: UUID, scheduledTime: Date) {
        let log = DoseLog(
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            takenTime: Date(),
            status: .taken
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseLogs()
            })
            .store(in: &cancellables)
    }
    
    func markDoseAsSkipped(medicationId: UUID, scheduledTime: Date) {
        let log = DoseLog(
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            takenTime: nil,
            status: .skipped
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseLogs()
            })
            .store(in: &cancellables)
    }
}

struct DoseLogWithMedication: Identifiable {
    let id = UUID()
    let doseLog: DoseLog
    let medication: Medication
}

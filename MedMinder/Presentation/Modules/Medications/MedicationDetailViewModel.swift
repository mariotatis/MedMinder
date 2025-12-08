import Foundation
import Combine

class MedicationDetailViewModel: ObservableObject {
    @Published var medication: Medication
    @Published var doseLogs: [DoseLog] = []
    @Published var upcomingDoses: [Date] = []
    @Published var currentDoseTime: Date
    @Published var profile: Profile?
    @Published var showTimeChangeConfirmation: Bool = false
    @Published var isDoseLogged: Bool = false
    @Published var currentDoseLog: DoseLog?
    
    private let medicationUseCases: MedicationUseCases
    private let treatmentUseCases: TreatmentUseCases
    private let profileUseCases: ProfileUseCases
    private let scheduledTime: Date
    private let originalScheduledTime: Date
    private var cancellables = Set<AnyCancellable>()
    
    init(medication: Medication, scheduledTime: Date, medicationUseCases: MedicationUseCases, treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases) {
        self.medication = medication
        self.scheduledTime = scheduledTime
        self.originalScheduledTime = scheduledTime
        self.currentDoseTime = scheduledTime
        self.medicationUseCases = medicationUseCases
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        
        fetchProfile()
        fetchDoseHistory()
        calculateUpcomingDoses()
        checkIfDoseLogged()
    }
    
    func fetchProfile() {
        treatmentUseCases.getTreatments()
            .map { treatments in
                treatments.first(where: { $0.id == self.medication.treatmentId })
            }
            .compactMap { $0 }
            .flatMap { [weak self] treatment -> AnyPublisher<Profile?, Never> in
                guard let self = self else { return Just(nil).eraseToAnyPublisher() }
                return self.profileUseCases.getProfiles()
                    .map { profiles in
                        profiles.first(where: { $0.id == treatment.profileId })
                    }
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profile in
                self?.profile = profile
            })
            .store(in: &cancellables)
    }
    
    func fetchDoseHistory() {
        medicationUseCases.getDoseLogs()
            .map { logs in
                logs.filter { $0.medicationId == self.medication.id }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] existingLogs in
                guard let self = self else { return }
                
                print("[MedicationDetail] Generating doses for medication: \(self.medication.name)")
                
                let calendar = Calendar.current
                let now = Date()
                
                // Calculate end date
                guard let endDate = calendar.date(byAdding: .day, value: self.medication.durationDays, to: self.medication.initialTime) else {
                    self.doseLogs = existingLogs.sorted(by: { $0.scheduledTime > $1.scheduledTime })
                    self.checkIfDoseLogged()
                    return
                }
                
                // Generate all expected dose times from initial time to end date
                var allExpectedDoses: [DoseLog] = []
                var currentTime = self.medication.initialTime
                let frequencyInterval = TimeInterval(self.medication.frequencyHours * 3600)
                
                var totalExpected = 0
                var foundExisting = 0
                var missedCount = 0
                
                while currentTime <= endDate {
                    totalExpected += 1
                    
                    // Check if a log exists for this scheduled time
                    if let existingLog = existingLogs.first(where: { log in
                        calendar.isDate(log.scheduledTime, equalTo: currentTime, toGranularity: .minute)
                    }) {
                        print("[MedicationDetail] Found existing log for: \(currentTime)")
                        allExpectedDoses.append(existingLog)
                        foundExisting += 1
                    } else {
                        // No log exists - create a pending entry (missed or upcoming)
                        let isPast = currentTime < now
                        if isPast {
                            print("[MedicationDetail] No log found for: \(currentTime) (missed dose)")
                            missedCount += 1
                        }
                        
                        let pendingLog = DoseLog(
                            medicationId: self.medication.id,
                            scheduledTime: currentTime,
                            takenTime: nil,
                            status: .pending
                        )
                        allExpectedDoses.append(pendingLog)
                    }
                    
                    currentTime = currentTime.addingTimeInterval(frequencyInterval)
                }
                
                print("[MedicationDetail] Total doses: \(totalExpected), Logged: \(foundExisting), Missed: \(missedCount)")
                
                // Filter to show only past/current doses (not future upcoming doses)
                // We only want to show doses up to "now" in the Dosage Registry section
                let pastDoses = allExpectedDoses.filter { $0.scheduledTime <= now }
                
                // Sort by most recent first
                self.doseLogs = pastDoses.sorted(by: { $0.scheduledTime > $1.scheduledTime })
                self.checkIfDoseLogged()
            })
            .store(in: &cancellables)
    }
    
    func checkIfDoseLogged() {
        let calendar = Calendar.current
        currentDoseLog = doseLogs.first(where: { log in
            calendar.isDate(log.scheduledTime, equalTo: originalScheduledTime, toGranularity: .minute)
        })
        // Only consider it logged if it's been marked as taken or skipped (not pending)
        isDoseLogged = currentDoseLog?.status == .taken || currentDoseLog?.status == .skipped
    }
    
    func calculateUpcomingDoses() {
        var doses: [Date] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate End Date
        guard let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) else { return }
        
        // Start from initial time and fast forward to now
        var doseTime = medication.initialTime
        
        // Skip past doses
        while doseTime < now {
            if let next = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: doseTime) {
                doseTime = next
            } else {
                break
            }
        }
        
        // Generate upcoming doses until endDate
        // Limit to a reasonable number (e.g., 50) to prevent infinite loops if something goes wrong
        var count = 0
        while doseTime <= endDate && count < 50 {
            doses.append(doseTime)
            if let next = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: doseTime) {
                doseTime = next
                count += 1
            } else {
                break
            }
        }
        
        self.upcomingDoses = doses
    }
    
    var isFutureDose: Bool {
        // Only consider it "future" if the scheduled time hasn't arrived yet
        // This allows marking any dose that is current or in the past
        return scheduledTime > Date()
    }
    
    func markAsTaken() {
        let calendar = Calendar.current
        let timeChanged = !calendar.isDate(currentDoseTime, equalTo: originalScheduledTime, toGranularity: .minute)
        
        if timeChanged {
            showTimeChangeConfirmation = true
        } else {
            logDoseAsTaken(updateFutureDoses: false)
        }
    }
    
    func logDoseAsTaken(updateFutureDoses: Bool) {
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: originalScheduledTime,
            takenTime: currentDoseTime,
            status: .taken
        )
        
        var publishers: [AnyPublisher<Void, Error>] = [medicationUseCases.logDose(log)]
        
        if updateFutureDoses {
            publishers.append(updateMedicationInitialTime())
        }
        
        Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseHistory()
                self?.calculateUpcomingDoses()
            })
            .store(in: &cancellables)
    }
    
    func markAsSkipped() {
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: originalScheduledTime,
            takenTime: nil,
            status: .skipped
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseHistory()
            })
            .store(in: &cancellables)
    }
    
    private func updateMedicationInitialTime() -> AnyPublisher<Void, Error> {
        var updatedMedication = medication
        updatedMedication.initialTime = currentDoseTime
        
        return medicationUseCases.updateMedication(updatedMedication)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.medication = updatedMedication
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Mark Specific Doses
    
    func markDoseAsTaken(scheduledTime: Date) {
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
            takenTime: Date(),
            status: .taken
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseHistory()
            })
            .store(in: &cancellables)
    }
    
    func markDoseAsSkipped(scheduledTime: Date) {
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
            takenTime: nil,
            status: .skipped
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoseHistory()
            })
            .store(in: &cancellables)
    }
}

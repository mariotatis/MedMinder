import Foundation
import Combine
import SwiftUI

class TreatmentMedicationDetailViewModel: ObservableObject {
    @Published var medication: Medication
    @Published var profile: Profile?
    @Published var upcomingDoses: [Date] = []
    @Published var allDoseLogs: [DoseLog] = [] // All doses including missed
    @Published var medicationWasDeleted = false
    @Published var isCompleted: Bool = false
    @Published var progress: Double = 0
    @Published var selectedSegment: Int = 0 // 0 = Upcoming, 1 = History
    @Published var currentDoseTime: Date = Date() // Time picker for marking doses
    @Published var showTimeChangeConfirmation: Bool = false
    @Published var isDoseLogged: Bool = false
    @AppStorage("actionWindowHours") private var actionWindowHours: Double = 4.0
    
    var isWithinActionWindow: Bool {
        guard let nextDose = upcomingDoses.first else { return false }
        let now = Date()
        let leadTimeSeconds = actionWindowHours * 3600
        let leadTimeBeforeScheduled = nextDose.addingTimeInterval(-leadTimeSeconds)
        // Allow actions from custom lead time before until 24 hours after
        return now >= leadTimeBeforeScheduled && now <= nextDose.addingTimeInterval(24 * 3600)
    }
    
    let medicationUseCases: MedicationUseCases
    private let profileUseCases: ProfileUseCases
    private let treatmentUseCases: TreatmentUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(medication: Medication, medicationUseCases: MedicationUseCases, profileUseCases: ProfileUseCases, treatmentUseCases: TreatmentUseCases) {
        self.medication = medication
        self.medicationUseCases = medicationUseCases
        self.profileUseCases = profileUseCases
        self.treatmentUseCases = treatmentUseCases
        self.currentDoseTime = Date() // Initialize with current time
    }
    
    func fetchData() {
        fetchProfile()
        fetchDoses()
    }
    
    func refreshData() {
        // Refresh medication data
        medicationUseCases.getMedications()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] medications in
                guard let self = self else { return }
                if let updated = medications.first(where: { $0.id == self.medication.id }) {
                    self.medication = updated
                    self.fetchDoses()
                } else {
                    self.medicationWasDeleted = true
                }
            })
            .store(in: &cancellables)
    }
    
    private func fetchProfile() {
        treatmentUseCases.getTreatments()
            .flatMap { [weak self] treatments -> AnyPublisher<Profile?, Error> in
                guard let self = self else {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                guard let treatment = treatments.first(where: { $0.id == self.medication.treatmentId }),
                      let profileId = treatment.profileId else {
                    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                return self.profileUseCases.getProfiles()
                    .map { profiles in profiles.first(where: { $0.id == profileId }) }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] profile in
                self?.profile = profile
            })
            .store(in: &cancellables)
    }
    
    private func fetchDoses() {
        medicationUseCases.getDoseLogs()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] logs in
                guard let self = self else { return }
                
                let medicationLogs = logs.filter { $0.medicationId == self.medication.id }
                
                // Generate all expected doses (including missed)
                self.generateAllDoses(existingLogs: medicationLogs)
                
                // Generate upcoming doses
                self.generateUpcomingDoses(existingLogs: medicationLogs)
                
                // Check completion
                self.checkCompletion(existingLogs: medicationLogs)
            })
            .store(in: &cancellables)
    }
    
    private func generateUpcomingDoses(existingLogs: [DoseLog]) {
        let now = Date()
        let calendar = Calendar.current
        
        let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) ?? now
        
        guard now < endDate else {
            upcomingDoses = []
            return
        }
        
        // Use minute precision for matching existing logs
        let existingScheduledTimes = Set(existingLogs.map { log in
            calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: log.scheduledTime))!
        })
        
        var doses: [Date] = []
        var currentTime = calendar.date(bySetting: .second, value: 0, of: medication.initialTime) ?? medication.initialTime
        let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
        
        while currentTime <= endDate {
            let normalizedTime = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentTime))!
            if !existingScheduledTimes.contains(normalizedTime) && currentTime >= now {
                doses.append(currentTime)
            }
            currentTime = currentTime.addingTimeInterval(frequencyInterval)
        }
        
        upcomingDoses = doses.sorted()
    }
    
    private func generateAllDoses(existingLogs: [DoseLog]) {
        let now = Date()
        let calendar = Calendar.current
        
        guard let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) else {
            self.allDoseLogs = existingLogs.sorted(by: { 
                ($0.takenTime ?? $0.scheduledTime) > ($1.takenTime ?? $1.scheduledTime)
            })
            return
        }
        
        // Start with ALL existing logs
        var allDoses = existingLogs
        
        // Track which "official" slots already have logs (using minute precision)
        let loggedSlots = Set(existingLogs.map { log in
            calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: log.scheduledTime))!
        })
        
        // Generate missing slots as "pending"
        var currentTime = calendar.date(bySetting: .second, value: 0, of: medication.initialTime) ?? medication.initialTime
        let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
        
        while currentTime <= endDate {
            let normalizedSlot = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentTime))!
            
            if !loggedSlots.contains(normalizedSlot) && currentTime <= now {
                // This slot was missed and has no skip/take log
                let pendingLog = DoseLog(
                    medicationId: medication.id,
                    scheduledTime: currentTime,
                    takenTime: nil,
                    status: .pending
                )
                allDoses.append(pendingLog)
            }
            
            currentTime = currentTime.addingTimeInterval(frequencyInterval)
        }
        
        // Sort everything: most recent first
        // Future upcoming doses (pending & scheduledTime > now) are not included in allDoseLogs
        self.allDoseLogs = allDoses
            .filter { $0.status != .pending || $0.scheduledTime <= now }
            .sorted { log1, log2 in
                let time1 = log1.takenTime ?? log1.scheduledTime
                let time2 = log2.takenTime ?? log2.scheduledTime
                return time1 > time2
            }
    }
    
    var missedDoseCount: Int {
        allDoseLogs.filter { $0.status == .pending && $0.scheduledTime < Date() }.count
    }
    
    private func checkCompletion(existingLogs: [DoseLog]) {
        let result = TreatmentProgressCalculator.calculateProgress(for: medication, logs: existingLogs)
        self.isCompleted = result.isCompleted
        self.progress = result.progress
    }
    
    // MARK: - Dose Logging
    
    func markAsTaken() {
        let timeDifference = abs(currentDoseTime.timeIntervalSince(Date()))
        let twentyMinutesInSeconds: TimeInterval = 20 * 60
        
        // Only show confirmation if time difference is greater than 20 minutes
        if timeDifference > twentyMinutesInSeconds {
            showTimeChangeConfirmation = true
        } else {
            logDoseAsTaken(updateFutureDoses: false)
        }
    }
    
    func logDoseAsTaken(updateFutureDoses: Bool) {
        // Find the next upcoming dose or use current time
        let scheduledTime = upcomingDoses.first ?? Date()
        
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
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
                self?.fetchDoses()
                self?.currentDoseTime = Date() // Reset to current time
            })
            .store(in: &cancellables)
    }
    
    func markDoseAsTaken(scheduledTime: Date, takenTime: Date = Date()) {
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
            takenTime: takenTime,
            status: .taken
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoses() // Changed from fetchDoseHistory() to fetchDoses() to match existing pattern
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
                self?.fetchDoses()
            })
            .store(in: &cancellables)
    }
    
    func markAsSkipped() {
        // Find the next upcoming dose or use current time
        let scheduledTime = upcomingDoses.first ?? Date()
        
        let log = DoseLog(
            medicationId: medication.id,
            scheduledTime: scheduledTime,
            takenTime: nil,
            status: .skipped
        )
        
        medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.fetchDoses()
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
}

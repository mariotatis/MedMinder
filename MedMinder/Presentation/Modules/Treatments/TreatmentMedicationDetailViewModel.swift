import Foundation
import Combine

class TreatmentMedicationDetailViewModel: ObservableObject {
    @Published var medication: Medication
    @Published var profile: Profile?
    @Published var upcomingDoses: [Date] = []
    @Published var doseHistory: [DoseLog] = []
    @Published var allDoseLogs: [DoseLog] = [] // All doses including missed
    @Published var medicationWasDeleted = false
    @Published var isCompleted: Bool = false
    @Published var selectedSegment: Int = 0 // 0 = Upcoming, 1 = History
    
    let medicationUseCases: MedicationUseCases
    private let profileUseCases: ProfileUseCases
    private let treatmentUseCases: TreatmentUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(medication: Medication, medicationUseCases: MedicationUseCases, profileUseCases: ProfileUseCases, treatmentUseCases: TreatmentUseCases) {
        self.medication = medication
        self.medicationUseCases = medicationUseCases
        self.profileUseCases = profileUseCases
        self.treatmentUseCases = treatmentUseCases
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
                
                // Filter history (taken or skipped), sorted by takenTime
                self.doseHistory = medicationLogs
                    .filter { $0.status == .taken || $0.status == .skipped }
                    .sorted { log1, log2 in
                        let time1 = log1.takenTime ?? log1.scheduledTime
                        let time2 = log2.takenTime ?? log2.scheduledTime
                        return time1 > time2
                    }
                
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
        
        // Calculate end date
        let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) ?? now
        
        // Only generate if medication hasn't ended
        guard now < endDate else {
            upcomingDoses = []
            return
        }
        
        // Get existing scheduled times
        let existingScheduledTimes = Set(existingLogs.map { $0.scheduledTime })
        
        // Generate doses from now until end date
        var doses: [Date] = []
        var currentTime = medication.initialTime
        let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
        
        while currentTime <= endDate {
            if !existingScheduledTimes.contains(currentTime) && currentTime >= now {
                doses.append(currentTime)
            }
            currentTime = currentTime.addingTimeInterval(frequencyInterval)
        }
        
        upcomingDoses = doses.sorted()
    }
    
    private func generateAllDoses(existingLogs: [DoseLog]) {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate end date
        guard let endDate = calendar.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime) else {
            self.allDoseLogs = existingLogs.sorted(by: { $0.scheduledTime > $1.scheduledTime })
            return
        }
        
        // Generate all expected dose times from initial time to end date
        var allExpectedDoses: [DoseLog] = []
        var currentTime = medication.initialTime
        let frequencyInterval = TimeInterval(medication.frequencyHours * 3600)
        
        while currentTime <= endDate {
            // Check if a log exists for this scheduled time
            if let existingLog = existingLogs.first(where: { log in
                calendar.isDate(log.scheduledTime, equalTo: currentTime, toGranularity: .minute)
            }) {
                allExpectedDoses.append(existingLog)
            } else {
                // No log exists - create a pending entry (missed or upcoming)
                let pendingLog = DoseLog(
                    medicationId: medication.id,
                    scheduledTime: currentTime,
                    takenTime: nil,
                    status: .pending
                )
                allExpectedDoses.append(pendingLog)
            }
            
            currentTime = currentTime.addingTimeInterval(frequencyInterval)
        }
        
        // Filter to show only past/current doses (not future upcoming doses)
        let pastDoses = allExpectedDoses.filter { $0.scheduledTime <= now }
        
        // Sort by most recent first, using takenTime for taken doses
        self.allDoseLogs = pastDoses.sorted(by: { log1, log2 in
            let time1 = log1.takenTime ?? log1.scheduledTime
            let time2 = log2.takenTime ?? log2.scheduledTime
            return time1 > time2
        })
    }
    
    var missedDoseCount: Int {
        allDoseLogs.filter { $0.status == .pending && $0.scheduledTime < Date() }.count
    }
    
    private func checkCompletion(existingLogs: [DoseLog]) {
        let durationDays = medication.durationDays
        let frequencyHours = medication.frequencyHours
        
        if durationDays <= 0 || frequencyHours <= 0 {
            self.isCompleted = false
            return
        }
        
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: durationDays, to: medication.initialTime) ?? Date()
        let frequencySeconds = Double(frequencyHours) * 3600
        
        var expectedDoses: [Date] = []
        var currentTime = medication.initialTime
        
        while currentTime <= endDate {
            expectedDoses.append(currentTime)
            currentTime += frequencySeconds
        }
        
        let takenLogs = existingLogs.filter { $0.status == .taken || $0.status == .skipped }
        
        self.isCompleted = takenLogs.count >= expectedDoses.count
    }
}

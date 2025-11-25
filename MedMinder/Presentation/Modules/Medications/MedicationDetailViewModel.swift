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
                    .sorted(by: { $0.scheduledTime > $1.scheduledTime })
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] logs in
                self?.doseLogs = logs
                self?.checkIfDoseLogged()
            })
            .store(in: &cancellables)
    }
    
    func checkIfDoseLogged() {
        let calendar = Calendar.current
        currentDoseLog = doseLogs.first(where: { log in
            calendar.isDate(log.scheduledTime, equalTo: originalScheduledTime, toGranularity: .minute)
        })
        isDoseLogged = currentDoseLog != nil
    }
    
    func calculateUpcomingDoses() {
        var doses: [Date] = []
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        
        var doseTime = calendar.date(bySettingHour: calendar.component(.hour, from: medication.initialTime),
                                     minute: calendar.component(.minute, from: medication.initialTime),
                                     second: 0, of: todayStart)!
        
        // Skip to the next upcoming dose
        while doseTime < now {
            if let next = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: doseTime) {
                doseTime = next
            } else {
                break
            }
        }
        
        // Calculate total number of doses based on duration
        let hoursInDay = 24
        let dosesPerDay = hoursInDay / medication.frequencyHours
        let totalDoses = dosesPerDay * medication.durationDays
        
        // Generate all upcoming doses for the duration
        for _ in 0..<totalDoses {
            doses.append(doseTime)
            if let next = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: doseTime) {
                doseTime = next
            } else {
                break
            }
        }
        
        self.upcomingDoses = doses
    }
    
    var isFutureDose: Bool {
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
}

import Foundation
import Combine

class TreatmentListViewModel: ObservableObject {
    @Published var treatments: [Treatment] = []
    @Published var profiles: [Profile] = []
    @Published var medications: [Medication] = []
    @Published var doseLogs: [DoseLog] = []
    
    private let treatmentUseCases: TreatmentUseCases
    private let profileUseCases: ProfileUseCases
    private let medicationUseCases: MedicationUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(treatmentUseCases: TreatmentUseCases, profileUseCases: ProfileUseCases, medicationUseCases: MedicationUseCases) {
        self.treatmentUseCases = treatmentUseCases
        self.profileUseCases = profileUseCases
        self.medicationUseCases = medicationUseCases
        fetchTreatments()
    }
    
    func fetchTreatments() {
        Publishers.Zip4(
            treatmentUseCases.getTreatments(),
            profileUseCases.getProfiles(),
            medicationUseCases.getMedications(),
            medicationUseCases.getDoseLogs()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] treatments, profiles, medications, logs in
            self?.treatments = treatments
            self?.profiles = profiles
            self?.medications = medications
            self?.doseLogs = logs
        })
        .store(in: &cancellables)
    }
    
    func getProfile(for profileId: UUID?) -> Profile? {
        guard let id = profileId else { return nil }
        return profiles.first(where: { $0.id == id })
    }
    
    func getProfileName(for treatment: Treatment) -> String {
        return profiles.first(where: { $0.id == treatment.profileId })?.name ?? "Unknown"
    }
    
    func getMedicationCount(for treatmentId: UUID) -> Int {
        return medications.filter { $0.treatmentId == treatmentId }.count
    }
    
    func isTreatmentCompleted(_ treatmentId: UUID) -> Bool {
        guard let treatment = treatments.first(where: { $0.id == treatmentId }) else { return false }
        
        let treatmentMeds = medications.filter { $0.treatmentId == treatmentId }
        guard !treatmentMeds.isEmpty else { return false }
        
        var allMedsCompleted = true
        
        for med in treatmentMeds {
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
            
            // We use a count-based check because users might take doses late or reschedule them,
            // causing the log timestamp to differ from the original schedule.
            // If the user has logged enough doses to cover the treatment duration, it is complete.
            let isMedComplete = medLogs.count >= expectedDoses.count
            
            if !isMedComplete {
                allMedsCompleted = false
                break
            }
        }
        
        if allMedsCompleted {
            return true
        }
        
        // Fallback: Old time-based logic (if user didn't log everything but time passed? 
        // Actually, if time passed but they didn't log, it's not "Completed" successfully.
        // But let's keep the old check for "Expired" treatments if that was the intent, 
        // OR just rely on the new logic which is stricter and more accurate for "Completion".
        // The user's request implies they WANT it to be completed because they took the dose.
        // So the new logic covers their case.
        
        // Let's keep the old logic as an OR condition? 
        // "Completed" usually means "Done successfully". 
        // If I missed a dose and the time ended, is it "Completed"? Maybe "Ended".
        // For now, I will return the result of the strict check, as it fixes the reported bug.
        
        return false
    }
}

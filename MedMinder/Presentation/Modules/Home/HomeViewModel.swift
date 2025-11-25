import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var todaySections: [HomeSection] = []
    @Published var tomorrowSections: [HomeSection] = []
    @Published var todayDateString: String = ""
    @Published var tomorrowDateString: String = ""
    
    // Remove old sections property if not needed, or keep for compatibility but we will use specific ones
    // @Published var sections: [HomeSection] = [] // Removing this to force UI update
    
    let medicationUseCases: MedicationUseCases
    let profileUseCases: ProfileUseCases
    let treatmentUseCases: TreatmentUseCases
    private var cancellables = Set<AnyCancellable>()
    
    // Cache
    private var medications: [Medication] = []
    private var profiles: [Profile] = []
    private var treatments: [Treatment] = []
    private var doseLogs: [DoseLog] = []
    
    init(medicationUseCases: MedicationUseCases, profileUseCases: ProfileUseCases, treatmentUseCases: TreatmentUseCases) {
        self.medicationUseCases = medicationUseCases
        self.profileUseCases = profileUseCases
        self.treatmentUseCases = treatmentUseCases
        fetchData()
    }
    
    func fetchData() {
        Publishers.CombineLatest4(
            medicationUseCases.getMedications(),
            profileUseCases.getProfiles(),
            treatmentUseCases.getTreatments(),
            medicationUseCases.getDoseLogs()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] meds, profs, treats, logs in
            self?.medications = meds
            self?.profiles = profs
            self?.treatments = treats
            self?.doseLogs = logs
            self?.generateSections()
        })
        .store(in: &cancellables)
    }
    
    private func generateSections() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // Date Strings
        self.todayDateString = "Today, \(formatDate(today))"
        self.tomorrowDateString = "Tomorrow, \(formatDate(tomorrow))"
        
        // Generate doses for Today and Tomorrow
        let todayDoses = generateDoses(for: today)
        let tomorrowDoses = generateDoses(for: tomorrow)
        
        // Group Today
        self.todaySections = groupDosesByTime(doses: todayDoses)
        
        // Group Tomorrow
        self.tomorrowSections = groupDosesByTime(doses: tomorrowDoses)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateString = formatter.string(from: date)
        
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return "\(dateString)\(suffix)"
    }
    
    private func generateDoses(for date: Date) -> [MedicationDose] {
        var doses: [MedicationDose] = []
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        for treatment in treatments {
            // Check if treatment is active for this date (broad check)
            if let endDate = treatment.endDate, startOfDay > endDate { continue }
            if startOfDay < calendar.startOfDay(for: treatment.startDate) { continue }
            
            let treatmentMeds = medications.filter { $0.treatmentId == treatment.id }
            
            for med in treatmentMeds {
                // Use initialTime as the anchor, but zero out seconds to match previous logic/logs
                guard let anchorDate = calendar.date(bySetting: .second, value: 0, of: med.initialTime) else { continue }
                
                // Calculate end date of medication using Calendar for accuracy
                guard let medEndDate = calendar.date(byAdding: .day, value: med.durationDays, to: anchorDate) else {
                    continue
                }
                
                // Check if medication is active on this day
                if startOfDay >= medEndDate {
                    continue
                }
                if endOfDay <= anchorDate {
                    continue
                }
                
                let frequencySeconds = Double(med.frequencyHours) * 3600
                guard frequencySeconds > 0 else { continue }
                
                // Calculate first dose time on or after startOfDay
                var firstDoseTime: Date
                if anchorDate >= startOfDay {
                    firstDoseTime = anchorDate
                } else {
                    let timeDiff = startOfDay.timeIntervalSince(anchorDate)
                    let intervals = ceil(timeDiff / frequencySeconds)
                    firstDoseTime = anchorDate.addingTimeInterval(intervals * frequencySeconds)
                }
                
                var currentDoseTime = firstDoseTime
                
                while currentDoseTime < endOfDay && currentDoseTime <= medEndDate {
                    let profile = profiles.first(where: { $0.id == treatment.profileId })
                    
                    // Check if this dose has been logged as taken or skipped
                    let doseLog = doseLogs.first(where: { log in
                        log.medicationId == med.id && calendar.isDate(log.scheduledTime, equalTo: currentDoseTime, toGranularity: .minute)
                    })
                    
                    let isLogged = doseLog != nil && (doseLog?.status == .taken || doseLog?.status == .skipped)
                    
                    if !isLogged {
                        let isTaken = doseLog?.status == .taken
                        doses.append(MedicationDose(id: UUID(), medication: med, profile: profile, scheduledTime: currentDoseTime, isTaken: isTaken))
                    }
                    
                    currentDoseTime.addTimeInterval(frequencySeconds)
                }
            }
        }
        return doses.sorted(by: { $0.scheduledTime < $1.scheduledTime })
    }
    
    private func groupDosesByTime(doses: [MedicationDose]) -> [HomeSection] {
        var sections: [HomeSection] = []
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // Determine current time period
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentPeriod: String
        if currentHour < 5 {
            currentPeriod = "Early Morning"
        } else if currentHour >= 5 && currentHour < 12 {
            currentPeriod = "Morning"
        } else if currentHour >= 12 && currentHour < 17 {
            currentPeriod = "Afternoon"
        } else {
            currentPeriod = "Evening"
        }
        
        let morning = doses.filter {
            let hour = calendar.component(.hour, from: $0.scheduledTime)
            return hour >= 5 && hour < 12
        }.sorted(by: { $0.scheduledTime < $1.scheduledTime })
        
        let afternoon = doses.filter {
            let hour = calendar.component(.hour, from: $0.scheduledTime)
            return hour >= 12 && hour < 17
        }.sorted(by: { $0.scheduledTime < $1.scheduledTime })
        
        let evening = doses.filter {
            let hour = calendar.component(.hour, from: $0.scheduledTime)
            return hour >= 17 || hour < 5
        }.sorted(by: { $0.scheduledTime < $1.scheduledTime })
        
        // Check if evening has early morning doses (before 5 AM)
        let hasEarlyMorningDoses = evening.contains { dose in
            let hour = calendar.component(.hour, from: dose.scheduledTime)
            return hour < 5
        }
        
        // If evening has early morning doses, show them first
        if hasEarlyMorningDoses && !evening.isEmpty {
            // Split evening into early morning (< 5 AM) and late evening (>= 17)
            let earlyMorning = evening.filter {
                let hour = calendar.component(.hour, from: $0.scheduledTime)
                return hour < 5
            }
            let lateEvening = evening.filter {
                let hour = calendar.component(.hour, from: $0.scheduledTime)
                return hour >= 17
            }
            
            if !earlyMorning.isEmpty {
                sections.append(HomeSection(title: "Early Morning", doses: earlyMorning, isCurrent: currentPeriod == "Early Morning"))
            }
            if !morning.isEmpty {
                sections.append(HomeSection(title: "Morning", doses: morning, isCurrent: currentPeriod == "Morning"))
            }
            if !afternoon.isEmpty {
                sections.append(HomeSection(title: "Afternoon", doses: afternoon, isCurrent: currentPeriod == "Afternoon"))
            }
            if !lateEvening.isEmpty {
                sections.append(HomeSection(title: "Evening", doses: lateEvening, isCurrent: currentPeriod == "Evening"))
            }
        } else {
            // Normal order
            if !morning.isEmpty { sections.append(HomeSection(title: "Morning", doses: morning, isCurrent: currentPeriod == "Morning")) }
            if !afternoon.isEmpty { sections.append(HomeSection(title: "Afternoon", doses: afternoon, isCurrent: currentPeriod == "Afternoon")) }
            if !evening.isEmpty { sections.append(HomeSection(title: "Evening", doses: evening, isCurrent: currentPeriod == "Evening")) }
        }
        
        return sections
    }
    
    func getProfile(for medication: Medication) -> Profile? {
        // Helper if needed, but now embedded in MedicationDose
        return nil
    }
}

struct HomeSection: Identifiable {
    let id = UUID()
    let title: String
    let doses: [MedicationDose]
    let isCurrent: Bool
}

struct MedicationDose: Identifiable {
    let id: UUID
    let medication: Medication
    let profile: Profile?
    let scheduledTime: Date
    let isTaken: Bool
}

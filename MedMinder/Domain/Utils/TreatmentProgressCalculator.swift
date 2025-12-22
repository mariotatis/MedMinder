import Foundation

/// Utility to calculate dose-based progress and completion status.
struct TreatmentProgressCalculator {
    
    struct ProgressResult {
        let progress: Double
        let isCompleted: Bool
        let loggedDosesCount: Int
        let totalExpectedDoses: Int
    }
    
    static func calculateProgress(for medication: Medication, logs: [DoseLog]) -> ProgressResult {
        let durationDays = medication.durationDays
        let frequencyHours = medication.frequencyHours
        
        // Handle cases with no duration or frequency
        if durationDays <= 0 || frequencyHours <= 0 {
            return ProgressResult(progress: 0, isCompleted: false, loggedDosesCount: 0, totalExpectedDoses: 0)
        }
        
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: durationDays, to: medication.initialTime) ?? Date()
        let frequencySeconds = Double(frequencyHours) * 3600
        
        var expectedDoseCount = 0
        var currentTime = medication.initialTime
        
        // Generate all scheduled times to get total expected count
        while currentTime <= endDate {
            expectedDoseCount += 1
            currentTime += frequencySeconds
        }
        
        // Count actual logs (Taken or Skipped)
        let medicationLogs = logs.filter { $0.medicationId == medication.id }
        let loggedCount = medicationLogs.filter { $0.status == .taken || $0.status == .skipped }.count
        
        let progress = expectedDoseCount > 0 ? min(Double(loggedCount) / Double(expectedDoseCount), 1.0) : 0
        let isCompleted = loggedCount >= expectedDoseCount && expectedDoseCount > 0
        
        return ProgressResult(
            progress: progress,
            isCompleted: isCompleted,
            loggedDosesCount: loggedCount,
            totalExpectedDoses: expectedDoseCount
        )
    }
    
    static func calculateTreatmentProgress(medications: [Medication], allLogs: [DoseLog]) -> ProgressResult {
        guard !medications.isEmpty else {
            return ProgressResult(progress: 0, isCompleted: false, loggedDosesCount: 0, totalExpectedDoses: 0)
        }
        
        var totalProgress: Double = 0
        var allCompleted = true
        var totalLogged = 0
        var totalExpected = 0
        
        for med in medications {
            let result = calculateProgress(for: med, logs: allLogs)
            totalProgress += result.progress
            if !result.isCompleted {
                allCompleted = false
            }
            totalLogged += result.loggedDosesCount
            totalExpected += result.totalExpectedDoses
        }
        
        return ProgressResult(
            progress: totalProgress / Double(medications.count),
            isCompleted: allCompleted,
            loggedDosesCount: totalLogged,
            totalExpectedDoses: totalExpected
        )
    }
}

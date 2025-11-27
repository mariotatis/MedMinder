import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    func scheduleReminders(for medication: Medication) {
        // Always check latest status before scheduling
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized)
                
                if !self.isAuthorized {
                    return
                }
                
                // Cancel existing reminders for this medication to avoid duplicates
                self.cancelReminders(for: medication) {
                    // Schedule for the next 7 days
                    let calendar = Calendar.current
                    let now = Date()
                    
                    // Calculate start date (today or start date if future)
                    let startDate = max(now, medication.initialTime)
                    
                    // Determine how many days to schedule, capped at 7 or the medication's duration
                    // We need to calculate the end date of the medication
                    let medicationEndDate = Calendar.current.date(byAdding: .day, value: medication.durationDays, to: medication.initialTime)!
                    
                    for dayOffset in 0..<7 {
                        guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                        
                        // Stop if we are past the medication's end date
                        if date > medicationEndDate { break }
                        
                        var currentDoseTime = medication.initialTime
                        
                        // Fast forward to the day we are scheduling
                        while currentDoseTime < calendar.startOfDay(for: date) {
                            currentDoseTime = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: currentDoseTime)!
                        }
                        
                        // Now schedule all doses that fall within this 'date'
                        while calendar.isDate(currentDoseTime, inSameDayAs: date) {
                            self.scheduleNotification(for: medication, at: currentDoseTime)
                            currentDoseTime = calendar.date(byAdding: .hour, value: medication.frequencyHours, to: currentDoseTime)!
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleNotification(for medication: Medication, at doseTime: Date) {
        // Trigger 5 minutes before
        let now = Date()
        guard let standardTriggerDate = Calendar.current.date(byAdding: .minute, value: -5, to: doseTime) else {
            return
        }
        
        var triggerDate = standardTriggerDate
        var isImmediate = false
        
        if standardTriggerDate < now {
            // If we missed the 5-min window, check if the dose is still in the future
            if doseTime > now {
                // Schedule immediately (5 seconds from now)
                triggerDate = now.addingTimeInterval(5)
                isImmediate = true
            } else {
                // Dose is in the past, don't schedule
                return
            }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "MedMinder"
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: doseTime)
        
        if isImmediate {
             content.body = "Your \(timeString) dose is coming up shortly. Track it in the app."
        } else {
             content.body = "Your \(timeString) dose is coming up. Track it in the app."
        }
        
        content.sound = .default
        
        let trigger: UNNotificationTrigger
        if isImmediate {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        
        // Unique ID: MedicationID + DoseTime
        let identifier = "\(medication.id.uuidString)-\(doseTime.timeIntervalSince1970)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func cancelReminders(for medication: Medication, completion: @escaping () -> Void = {}) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { return }
            let ids = requests.filter { $0.identifier.starts(with: medication.id.uuidString) }.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
            completion()
        }
    }
    
    func cancelSpecificReminder(for medicationId: UUID, at scheduledTime: Date) {
        // The ID format is UUID-TimeInterval
        // We need to match loosely or reconstruct the ID.
        // Since floating point time interval might vary slightly, let's try to reconstruct it exactly as scheduled.
        // Or better, search for identifiers starting with UUID and check the trigger date.
        
        // Reconstruct ID approach (must match schedule logic exactly)
        let identifier = "\(medicationId.uuidString)-\(scheduledTime.timeIntervalSince1970)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
    
    func rescheduleAll(medications: [Medication]) {
        cancelAll()
        for medication in medications {
            scheduleReminders(for: medication)
        }
    }
}

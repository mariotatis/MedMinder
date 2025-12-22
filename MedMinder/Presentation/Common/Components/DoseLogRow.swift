import SwiftUI

struct DoseLogRow: View {
    let medication: Medication? // Optional: used when showing in a list of mixed medications
    let log: DoseLog
    let onTaken: (Date) -> Void
    let onSkipped: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status Icon
            statusIcon
            
            VStack(alignment: .leading, spacing: 4) {
                // Medication Name and Dosage (if provided)
                if let medication = medication {
                    Text("\(medication.name), \(medication.dosage)")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                }
                
                // Status Description and Time
                statusText
                
                // Date
                Text(log.scheduledTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                
                // Action buttons for missed doses (only show for past doses)
                if log.status == .pending && log.scheduledTime < Date() {
                    MissedDoseActionsView(
                        scheduledTime: log.scheduledTime,
                        onTaken: onTaken,
                        onSkipped: onSkipped
                    )
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        Group {
            if log.status == .taken {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if log.status == .skipped {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            } else {
                // Pending - red for missed, grey for upcoming
                Image(systemName: "clock")
                    .foregroundColor(log.scheduledTime < Date() ? .red : .gray)
            }
        }
        .font(.title2)
    }
    
    @ViewBuilder
    private var statusText: some View {
        if let takenTime = log.takenTime {
            Text("Taken at \(takenTime, style: .time)")
                .font(.body)
                .foregroundColor(.textPrimary)
        } else if log.status == .skipped {
            Text("Skipped")
                .font(.body)
                .foregroundColor(.orange)
        } else if log.status == .pending {
            if log.scheduledTime < Date() {
                // Missed dose
                HStack(spacing: 4) {
                    Text("Missed:")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("\(log.scheduledTime, style: .time)")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                }
            } else {
                // Upcoming dose
                Text("Scheduled for \(log.scheduledTime, style: .time)")
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

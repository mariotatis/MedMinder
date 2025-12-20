import SwiftUI

struct MissedDoseActionsView: View {
    let scheduledTime: Date
    let onTaken: (Date) -> Void
    let onSkipped: () -> Void
    
    @State private var selectedTime: Date
    
    init(scheduledTime: Date, onTaken: @escaping (Date) -> Void, onSkipped: @escaping () -> Void) {
        self.scheduledTime = scheduledTime
        self.onTaken = onTaken
        self.onSkipped = onSkipped
        _selectedTime = State(initialValue: scheduledTime)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                onTaken(selectedTime)
            }) {
                Text("Taken")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            Button(action: onSkipped) {
                Text("Skipped")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
                .frame(maxWidth: 100)
        }
    }
}

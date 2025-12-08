import SwiftUI

struct MedicationCard: View {
    let medication: Medication
    let profile: Profile?
    let time: Date
    var isCurrentPeriod: Bool = false
    var treatmentName: String? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: medication.color.darkHex))
                    .frame(width: 60, height: 60)
                
                Image(systemName: medication.type.iconName)
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("\(medication.dosage)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                if let treatmentName = treatmentName {
                    Text(treatmentName)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary.opacity(0.8))
                }
                
                HStack(spacing: 4) {
                    Text("Next Dose:")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Text(time, style: .time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
            }
            
            Spacer()
            
            // Profile
            if let profile = profile {
                ProfileAvatar(profile: profile, size: 60)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .background(isCurrentPeriod ? Color.blue.opacity(0.1) : Color.surface)
        .cornerRadius(16)
    }
}



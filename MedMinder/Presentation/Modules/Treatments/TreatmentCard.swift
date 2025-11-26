import SwiftUI

struct TreatmentCard: View {
    let treatment: Treatment
    let profile: Profile?
    let medicationCount: Int
    var isCompleted: Bool = false
    var showChevron: Bool = false
    var showProfileInfo: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(treatment.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    if isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                }
                
                if showProfileInfo {
                    if let profile = profile {
                        Text("For \(profile.name)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("Unassigned")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Text("Started: ")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
                + Text("\(treatment.startDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                Text("Medications: ")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textSecondary)
                + Text("\(medicationCount)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            if showProfileInfo {
                ProfileAvatar(profile: profile, size: 70)
                    .padding(.trailing, 4)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }
}

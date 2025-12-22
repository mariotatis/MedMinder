import SwiftUI

struct TreatmentCard: View {
    let treatment: Treatment
    let profile: Profile?
    let medicationCount: Int
    var isCompleted: Bool = false
    var showChevron: Bool = false
    var showProfileInfo: Bool = true
    var progress: Double? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(treatment.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                }
                
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
                
                if !isCompleted, let progressValue = progress ?? (treatment.endDate.map { endDate in
                    let totalDuration = endDate.timeIntervalSince(treatment.startDate)
                    guard totalDuration > 0 else { return 0.0 }
                    let elapsed = Date().timeIntervalSince(treatment.startDate)
                    return min(max(elapsed / totalDuration, 0), 1)
                }) {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3)) // Darker background track
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primaryAction)
                                    .frame(width: geometry.size.width * CGFloat(progressValue), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(Int(progressValue * 100))% Completed")
                            .font(.caption) // Larger font
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 4)
                }

                Text("Started: \(treatment.startDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                Text("Medications: \(medicationCount)")
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
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }
}

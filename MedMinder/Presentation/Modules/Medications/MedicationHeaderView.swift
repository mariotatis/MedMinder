import SwiftUI

struct MedicationHeaderView: View {
    let medication: Medication
    let profile: Profile?
    let isCompleted: Bool
    let progress: Double?
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: medication.color.darkHex))
                    .frame(width: 60, height: 60)
                
                Image(systemName: medication.type.iconName)
                    .font(.title)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                if let profile = profile {
                    Text("\(medication.dosage), For \(profile.name)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                } else {
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
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
                } else if let progressValue = progress {
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3)) // Darker background track
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: medication.color.darkHex))
                                    .frame(width: geometry.size.width * CGFloat(progressValue), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        Text("\(Int(progressValue * 100))% Completed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if let profile = profile {
                ProfileAvatar(profile: profile, size: 60)
                    .padding(.trailing, 4)
            }
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }
}

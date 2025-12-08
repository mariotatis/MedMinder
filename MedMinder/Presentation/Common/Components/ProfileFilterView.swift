import SwiftUI

struct ProfileFilterView: View {
    let profiles: [Profile]
    let selectedProfileId: UUID?
    let onSelect: (UUID?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "All" option
            Button(action: {
                onSelect(nil)
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary)
                        )
                    
                    Text("All")
                        .font(.body)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if selectedProfileId == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.primaryAction)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(selectedProfileId == nil ? Color.primaryAction.opacity(0.1) : Color.clear)
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.vertical, 4)
            
            // Profile options
            ForEach(profiles) { profile in
                Button(action: {
                    onSelect(profile.id)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        ProfileAvatar(profile: profile, size: 32)
                        
                        Text(profile.name)
                            .font(.body)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        if selectedProfileId == profile.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.primaryAction)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selectedProfileId == profile.id ? Color.primaryAction.opacity(0.1) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(minWidth: 200)
        .background(Color.surface)
        .cornerRadius(12)
    }
}

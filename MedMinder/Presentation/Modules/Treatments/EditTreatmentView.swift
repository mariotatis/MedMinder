import SwiftUI

struct EditTreatmentView: View {
    @ObservedObject var viewModel: AddTreatmentViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CustomTextField(title: "Treatment Name", placeholder: "e.g. Post-Surgery Recovery", text: $viewModel.name)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who is this for?")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // None / Temp Profile Option
                                VStack {
                                    ProfileAvatar(
                                        profile: nil,
                                        size: 80,
                                        showBorder: true,
                                        isSelected: viewModel.selectedProfileId == nil
                                    )
                                    .onTapGesture {
                                        viewModel.selectedProfileId = nil
                                        hideKeyboard()
                                    }
                                    
                                    Text("None")
                                        .font(.caption)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                ForEach(viewModel.profiles) { profile in
                                    VStack {
                                        ProfileAvatar(
                                            profile: profile,
                                            size: 80,
                                            showBorder: true,
                                            isSelected: viewModel.selectedProfileId == profile.id
                                        )
                                        .onTapGesture {
                                            viewModel.selectedProfileId = profile.id
                                            hideKeyboard()
                                        }
                                        
                                        Text(profile.name)
                                            .font(.caption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                                
                                NavigationLink(destination: AddProfileView(
                                    viewModel: AddProfileViewModel(
                                        profileUseCases: viewModel.profileUseCases,
                                        onSave: { newProfile in
                                            viewModel.fetchProfiles()
                                            if let profile = newProfile {
                                                viewModel.selectedProfileId = profile.id
                                            }
                                        }
                                    ),
                                    showCloseButton: false
                                )) {
                                    VStack {
                                        Circle()
                                            .fill(Color.surface)
                                            .frame(width: 80, height: 80)
                                            .overlay(Image(systemName: "plus").foregroundColor(.primaryAction))
                                        Text("Add Profile")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 12)
                        }
                    }
                    
                    Spacer()
                    
                    // Delete Treatment Button
                    Button(action: {
                        viewModel.showDeleteConfirmation = true
                    }) {
                        Text("Remove Treatment")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .alert(isPresented: $viewModel.showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Treatment"),
                            message: Text("Are you sure you want to delete this treatment? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.deleteTreatment()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Edit Treatment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if !viewModel.name.isEmpty {
                        viewModel.saveTreatment()
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        viewModel.saveTreatment() // Triggers error
                    }
                }) {
                    Text("Save")
                        .foregroundColor(.primaryAction)
                }
            }
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

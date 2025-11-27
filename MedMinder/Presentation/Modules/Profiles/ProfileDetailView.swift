import SwiftUI

struct ProfileDetailView: View {
    @StateObject var viewModel: ProfileDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile = false
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        ProfileAvatar(profile: viewModel.profile, size: 150)
                        
                        VStack(spacing: 4) {
                            Text(viewModel.profile.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            if viewModel.profile.age > 0 {
                                Text("\(viewModel.profile.age) years old")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    .padding(.top, 32)
                    
                    // Associated Treatments
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Treatments")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal)
                        
                        if viewModel.treatments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "pills")
                                    .font(.largeTitle)
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                Text("No treatments assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color.surface.opacity(0.5))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.treatments) { treatment in
                                    NavigationLink(destination: AddTreatmentView(viewModel: AddTreatmentViewModel(
                                        treatmentUseCases: viewModel.treatmentUseCases,
                                        profileUseCases: viewModel.profileUseCases,
                                        medicationUseCases: viewModel.medicationUseCases,
                                        treatment: treatment
                                    ))) {
                                        TreatmentCard(
                                            treatment: treatment,
                                            profile: viewModel.profile,
                                            medicationCount: viewModel.getMedicationCount(for: treatment.id),
                                            isCompleted: viewModel.isTreatmentCompleted(treatment.id),
                                            showChevron: true,
                                            showProfileInfo: false
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEditProfile = true }) {
                    Text("Edit")
                        .foregroundColor(.primaryAction)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            NavigationView {
                AddProfileView(viewModel: AddProfileViewModel(
                    profileUseCases: viewModel.profileUseCases,
                    profile: viewModel.profile,
                    onSave: { _ in 
                        viewModel.refreshProfile()
                    }
                ))
            }
        }
        .onAppear {
            viewModel.fetchTreatments()
            viewModel.fetchMedications()
            viewModel.fetchDoseLogs()
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

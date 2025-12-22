import SwiftUI

struct ProfileDetailView: View {
    @StateObject var viewModel: ProfileDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditProfile = false
    @State private var showAddTreatment = false
    
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
                        HStack {
                            Text("Treatments")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Button(action: { showAddTreatment = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primaryAction)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.treatments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "pills")
                                    .font(.largeTitle)
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                Text("No treatments assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                
                                Button(action: { showAddTreatment = true }) {
                                    Text("Add Treatment")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.primaryAction)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
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
                                            showProfileInfo: false,
                                            progress: viewModel.getTreatmentProgress(for: treatment.id)
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
        .sheet(isPresented: $showAddTreatment) {
            NavigationView {
                AddTreatmentView(
                    viewModel: AddTreatmentViewModel(
                        treatmentUseCases: viewModel.treatmentUseCases,
                        profileUseCases: viewModel.profileUseCases,
                        medicationUseCases: viewModel.medicationUseCases,
                        preselectedProfileId: viewModel.profile.id
                    ),
                    showCloseButton: true
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onDisappear {
                // Refresh treatments when returning (though ProfileDetailViewModel might strictly be reactive if using publishers correctly)
                // Assuming viewModel updates automatically via publishers or we might need a refresh trigger if not.
                // ProfileDetailViewModel uses a fetch method, so we should probably trigger it.
                // However, the ViewModel seems to use plain arrays. Let's force a refresh just to be safe if possible, 
                // but for now relying on SwiftUI lifecycle or if needed we can add .onAppear to the view itself which is already there.
                viewModel.fetchTreatments() 
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
            .navigationViewStyle(StackNavigationViewStyle())
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

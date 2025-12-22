import SwiftUI

struct ProfileListView: View {
    @StateObject var viewModel: ProfileListViewModel
    @State private var showAddProfile = false
    @State private var hasAppeared = false
    
    // Dependency
    let profileUseCases: ProfileUseCases
    let treatmentUseCases: TreatmentUseCases
    let medicationUseCases: MedicationUseCases
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                if viewModel.profiles.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.textSecondary)
                        Text("No family members")
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                        Text("Add profiles to manage medications for your family.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showAddProfile = true }) {
                            Text("Add Family Member")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.primaryAction)
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                NavigationLink(destination: ProfileDetailView(viewModel: ProfileDetailViewModel(
                                    profile: profile,
                                    treatmentUseCases: treatmentUseCases,
                                    profileUseCases: profileUseCases,
                                    medicationUseCases: medicationUseCases,
                                    onDelete: { viewModel.fetchProfiles() },
                                    onUpdate: { viewModel.fetchProfiles() }
                                ))) {
                                    HStack(spacing: 16) {
                                        ProfileAvatar(profile: profile, size: 60)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profile.name)
                                                .font(.headline)
                                                .foregroundColor(.textPrimary)
                                            
                                            if profile.age > 0 {
                                                Text("\(profile.age) years old")
                                                    .font(.subheadline)
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Family Members")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddProfile = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primaryAction)
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                NavigationView {
                    AddProfileView(viewModel: AddProfileViewModel(
                        profileUseCases: viewModel.profileUseCases,
                        onSave: { _ in viewModel.fetchProfiles() }
                    ))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !hasAppeared {
                viewModel.fetchProfiles()
                hasAppeared = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Only refresh when app comes to foreground, not on tab switches
        }
    }
}
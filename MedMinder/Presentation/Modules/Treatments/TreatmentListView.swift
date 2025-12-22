import SwiftUI

struct TreatmentListView: View {
    @StateObject var viewModel: TreatmentListViewModel
    @State private var showAddTreatment = false
    @State private var isActive = false
    
    // Dependencies for the AddTreatmentView
    let treatmentUseCases: TreatmentUseCases
    let profileUseCases: ProfileUseCases
    let medicationUseCases: MedicationUseCases
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
                if viewModel.treatments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "pills")
                            .font(.system(size: 60))
                            .foregroundColor(.textSecondary)
                        Text("No treatments yet")
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                        Text("Add a treatment to start tracking medications.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showAddTreatment = true }) {
                            Text("Add Treatment")
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
                            ForEach(viewModel.treatments) { treatment in
                                NavigationLink(destination: AddTreatmentView(viewModel: AddTreatmentViewModel(
                                    treatmentUseCases: treatmentUseCases,
                                    profileUseCases: profileUseCases,
                                    medicationUseCases: medicationUseCases,
                                    treatment: treatment
                                ))) {
                                    TreatmentCard(
                                        treatment: treatment,
                                        profile: viewModel.getProfile(for: treatment.profileId),
                                        medicationCount: viewModel.getMedicationCount(for: treatment.id),
                                        isCompleted: viewModel.isTreatmentCompleted(treatment.id),
                                        showChevron: true,
                                        progress: viewModel.getTreatmentProgress(for: treatment.id)
                                    )
                                 }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Treatments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddTreatment = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primaryAction)
                    }
                }
            }
            .sheet(isPresented: $showAddTreatment) {
                NavigationView {
                AddTreatmentView(
                    viewModel: AddTreatmentViewModel(
                        treatmentUseCases: treatmentUseCases,
                        profileUseCases: profileUseCases,
                        medicationUseCases: medicationUseCases
                    ),
                    showCloseButton: true
                )
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            .onAppear {
                viewModel.fetchTreatments()
            }
            .onChange(of: showAddTreatment) { oldValue, isPresented in
                if !isPresented {
                    viewModel.fetchTreatments()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
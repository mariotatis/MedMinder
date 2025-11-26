import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    @State private var showAddTreatment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                if viewModel.todaySections.isEmpty && viewModel.tomorrowSections.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.textSecondary)
                        Text("All caught up!")
                            .font(.title2)
                            .foregroundColor(.textPrimary)
                        Text("No upcoming medications.")
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
                        LazyVStack(alignment: .leading, spacing: 24) {
                            // Today Section
                            if !viewModel.todaySections.isEmpty {
                                Text(viewModel.todayDateString)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                
                                ForEach(viewModel.todaySections) { section in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(section.title)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.textPrimary)
                                            .padding(.horizontal)
                                        
                                        ForEach(section.doses) { dose in
                                            NavigationLink(destination: MedicationDetailView(
                                                viewModel: MedicationDetailViewModel(
                                                    medication: dose.medication,
                                                    scheduledTime: dose.scheduledTime,
                                                    medicationUseCases: viewModel.medicationUseCases,
                                                    treatmentUseCases: viewModel.treatmentUseCases,
                                                    profileUseCases: viewModel.profileUseCases
                                                )
                                            )) {
                                                MedicationCard(
                                                    medication: dose.medication,
                                                    profile: dose.profile,
                                                    time: dose.scheduledTime,
                                                    isCurrentPeriod: section.isCurrent,
                                                    treatmentName: dose.treatmentName
                                                )
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            
                            // Tomorrow Section
                            if !viewModel.tomorrowSections.isEmpty {
                                if !viewModel.todaySections.isEmpty {
                                    Divider()
                                        .padding(.vertical, 16)
                                }
                                
                                Text(viewModel.tomorrowDateString)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.tomorrowSections) { section in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(section.title)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.textPrimary)
                                            .padding(.horizontal)
                                        
                                        ForEach(section.doses) { dose in
                                            NavigationLink(destination: MedicationDetailView(
                                                viewModel: MedicationDetailViewModel(
                                                    medication: dose.medication,
                                                    scheduledTime: dose.scheduledTime,
                                                    medicationUseCases: viewModel.medicationUseCases,
                                                    treatmentUseCases: viewModel.treatmentUseCases,
                                                    profileUseCases: viewModel.profileUseCases
                                                )
                                            )) {
                                                MedicationCard(
                                                    medication: dose.medication,
                                                    profile: dose.profile,
                                                    time: dose.scheduledTime,
                                                    isCurrentPeriod: false,
                                                    treatmentName: dose.treatmentName
                                                )
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(greeting)
            .sheet(isPresented: $showAddTreatment) {
                NavigationView {
                    AddTreatmentView(viewModel: AddTreatmentViewModel(
                        treatmentUseCases: viewModel.treatmentUseCases,
                        profileUseCases: viewModel.profileUseCases,
                        medicationUseCases: viewModel.medicationUseCases
                    ))
                }
            }
            .onAppear {
                viewModel.fetchData()
            }
            .onChange(of: showAddTreatment) { isPresented in
                if !isPresented {
                    viewModel.fetchData()
                }
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

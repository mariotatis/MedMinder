import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    @State private var showAddTreatment = false
    @State private var showFilterPopover = false
    @State private var cancellables = Set<AnyCancellable>()
    
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
                                            if dose.isWithinActionWindow {
                                                // Show card with action buttons (no navigation)
                                                VStack(spacing: 0) {
                                                    MedicationCard(
                                                        medication: dose.medication,
                                                        profile: dose.profile,
                                                        time: dose.scheduledTime,
                                                        isCurrentPeriod: section.isCurrent,
                                                        treatmentName: dose.treatmentName
                                                    )
                                                    
                                                    // Action buttons
                                                    HStack(spacing: 12) {
                                                        Button(action: {
                                                            markDoseAsTaken(dose: dose)
                                                        }) {
                                                            Text("Mark as Taken")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(.white)
                                                                .frame(maxWidth: .infinity)
                                                                .padding(.vertical, 12)
                                                                .background(Color.green)
                                                                .cornerRadius(10)
                                                        }
                                                        
                                                        Button(action: {
                                                            markDoseAsSkipped(dose: dose)
                                                        }) {
                                                            Text("Mark as Skipped")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(.white)
                                                                .frame(maxWidth: .infinity)
                                                                .padding(.vertical, 12)
                                                                .background(Color.orange)
                                                                .cornerRadius(10)
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                    .padding(.bottom, 12)
                                                    .background(section.isCurrent ? Color.blue.opacity(0.1) : Color.surface)
                                                }
                                                .cornerRadius(16)
                                                .padding(.horizontal)
                                            } else {
                                                // Show as NavigationLink (normal behavior)
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
                                            if dose.isWithinActionWindow {
                                                // Show card with action buttons (no navigation)
                                                VStack(spacing: 0) {
                                                    MedicationCard(
                                                        medication: dose.medication,
                                                        profile: dose.profile,
                                                        time: dose.scheduledTime,
                                                        isCurrentPeriod: false,
                                                        treatmentName: dose.treatmentName
                                                    )
                                                    
                                                    // Action buttons
                                                    HStack(spacing: 12) {
                                                        Button(action: {
                                                            markDoseAsTaken(dose: dose)
                                                        }) {
                                                            Text("Mark as Taken")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(.white)
                                                                .frame(maxWidth: .infinity)
                                                                .padding(.vertical, 12)
                                                                .background(Color.green)
                                                                .cornerRadius(10)
                                                        }
                                                        
                                                        Button(action: {
                                                            markDoseAsSkipped(dose: dose)
                                                        }) {
                                                            Text("Mark as Skipped")
                                                                .font(.subheadline)
                                                                .fontWeight(.medium)
                                                                .foregroundColor(.white)
                                                                .frame(maxWidth: .infinity)
                                                                .padding(.vertical, 12)
                                                                .background(Color.orange)
                                                                .cornerRadius(10)
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                    .padding(.bottom, 12)
                                                    .background(Color.surface)
                                                }
                                                .cornerRadius(16)
                                                .padding(.horizontal)
                                            } else {
                                                // Show as NavigationLink (normal behavior)
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
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(greeting)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterPopover = true
                    }) {
                        Image(systemName: viewModel.selectedProfileId == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundColor(viewModel.selectedProfileId == nil ? .textSecondary : .primaryAction)
                    }
                    .popover(isPresented: $showFilterPopover) {
                        ProfileFilterView(
                            profiles: viewModel.availableProfiles,
                            selectedProfileId: viewModel.selectedProfileId,
                            onSelect: { profileId in
                                if let profileId = profileId {
                                    viewModel.setFilter(profileId: profileId)
                                } else {
                                    viewModel.clearFilter()
                                }
                            }
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
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
    
    // Helper methods for marking doses
    private func markDoseAsTaken(dose: MedicationDose) {
        let log = DoseLog(
            medicationId: dose.medication.id,
            scheduledTime: dose.scheduledTime,
            takenTime: Date(),
            status: .taken
        )
        
        viewModel.medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [viewModel] _ in
                viewModel.fetchData()
            })
            .store(in: &cancellables)
    }
    
    private func markDoseAsSkipped(dose: MedicationDose) {
        let log = DoseLog(
            medicationId: dose.medication.id,
            scheduledTime: dose.scheduledTime,
            takenTime: nil,
            status: .skipped
        )
        
        viewModel.medicationUseCases.logDose(log)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [viewModel] _ in
                viewModel.fetchData()
            })
            .store(in: &cancellables)
    }
}

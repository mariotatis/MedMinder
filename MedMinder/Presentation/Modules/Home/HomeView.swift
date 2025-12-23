import SwiftUI
import Combine

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    
    @State private var showAddTreatment = false
    @State private var showFilterPopover = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var doseTimes: [String: Date] = [:] // Track time for each dose by medication ID + scheduled time
    @State private var showTimeChangeConfirmation = false
    @State private var pendingDoseAction: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                
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
                                                // Show card with action buttons (wrapped in NavigationLink)
                                                NavigationLink(destination: UnifiedMedicationDetailView(
                                                    viewModel: TreatmentMedicationDetailViewModel(
                                                        medication: dose.medication,
                                                        medicationUseCases: viewModel.medicationUseCases,
                                                        profileUseCases: viewModel.profileUseCases,
                                                        treatmentUseCases: viewModel.treatmentUseCases
                                                    )
                                                )) {
                                                    VStack(spacing: 0) {
                                                        MedicationCard(
                                                            medication: dose.medication,
                                                            profile: dose.profile,
                                                            time: dose.scheduledTime,
                                                            isCurrentPeriod: section.isCurrent,
                                                            treatmentName: dose.treatmentName,
                                                            roundedCorners: [.topLeft, .topRight]
                                                        )
                                                        
                                                        
                                                        // Time picker and action buttons in one row
                                                        HStack(spacing: 8) {
                                                            // Action buttons
                                                            Button(action: {
                                                                markDoseAsTaken(dose: dose)
                                                            }) {
                                                                Text("Taken")
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.white)
                                                                    .frame(maxWidth: .infinity)
                                                                    .padding(.vertical, 8)
                                                                    .padding(.horizontal, 4)
                                                                    .background(Color.green)
                                                                    .cornerRadius(8)
                                                            }
                                                            
                                                            Button(action: {
                                                                markDoseAsSkipped(dose: dose)
                                                            }) {
                                                                Text("Skipped")
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.white)
                                                                    .frame(maxWidth: .infinity)
                                                                    .padding(.vertical, 8)
                                                                    .padding(.horizontal, 4)
                                                                    .background(Color.orange)
                                                                    .cornerRadius(8)
                                                            }
                                                            
                                                            // Time picker
                                                            DatePicker("", selection: Binding(
                                                                get: { getDoseTime(for: dose) },
                                                                set: { setDoseTime(for: dose, time: $0) }
                                                            ), displayedComponents: .hourAndMinute)
                                                                .datePickerStyle(CompactDatePickerStyle())
                                                                .labelsHidden()
                                                                .frame(maxWidth: 100)
                                                        }
                                                        .padding(.horizontal)
                                                        .padding(.vertical, 10)
                                                        .background(section.isCurrent ? Color.primaryAction.opacity(0.1) : Color.surface)
                                                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(.horizontal)
                                            } else {
                                                // Show as NavigationLink (normal behavior)
                                                NavigationLink(destination: UnifiedMedicationDetailView(
                                                    viewModel: TreatmentMedicationDetailViewModel(
                                                        medication: dose.medication,
                                                        medicationUseCases: viewModel.medicationUseCases,
                                                        profileUseCases: viewModel.profileUseCases,
                                                        treatmentUseCases: viewModel.treatmentUseCases
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
                                                // Show card with action buttons (wrapped in NavigationLink)
                                                NavigationLink(destination: UnifiedMedicationDetailView(
                                                    viewModel: TreatmentMedicationDetailViewModel(
                                                        medication: dose.medication,
                                                        medicationUseCases: viewModel.medicationUseCases,
                                                        profileUseCases: viewModel.profileUseCases,
                                                        treatmentUseCases: viewModel.treatmentUseCases
                                                    )
                                                )) {
                                                    VStack(spacing: 0) {
                                                        MedicationCard(
                                                            medication: dose.medication,
                                                            profile: dose.profile,
                                                            time: dose.scheduledTime,
                                                            isCurrentPeriod: false,
                                                            treatmentName: dose.treatmentName,
                                                            roundedCorners: [.topLeft, .topRight]
                                                        )
                                                        
                                                        
                                                        // Time picker and action buttons in one row
                                                        HStack(spacing: 8) {
                                                            // Action buttons
                                                            Button(action: {
                                                                markDoseAsTaken(dose: dose)
                                                            }) {
                                                                Text("Taken")
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.white)
                                                                    .frame(maxWidth: .infinity)
                                                                    .padding(.vertical, 8)
                                                                    .padding(.horizontal, 4)
                                                                    .background(Color.green)
                                                                    .cornerRadius(8)
                                                            }
                                                            
                                                            Button(action: {
                                                                markDoseAsSkipped(dose: dose)
                                                            }) {
                                                                Text("Skipped")
                                                                    .font(.caption)
                                                                    .fontWeight(.semibold)
                                                                    .foregroundColor(.white)
                                                                    .frame(maxWidth: .infinity)
                                                                    .padding(.vertical, 8)
                                                                    .padding(.horizontal, 4)
                                                                    .background(Color.orange)
                                                                    .cornerRadius(8)
                                                            }
                                                            
                                                            // Time picker
                                                            DatePicker("", selection: Binding(
                                                                get: { getDoseTime(for: dose) },
                                                                set: { setDoseTime(for: dose, time: $0) }
                                                            ), displayedComponents: .hourAndMinute)
                                                                .datePickerStyle(CompactDatePickerStyle())
                                                                .labelsHidden()
                                                                .frame(maxWidth: 100)
                                                        }
                                                        .padding(.horizontal)
                                                        .padding(.vertical, 10)
                                                        .background(Color.surface)
                                                        .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                                                    }
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                .padding(.horizontal)
                                            } else {
                                                // Show as NavigationLink (normal behavior)
                                                NavigationLink(destination: UnifiedMedicationDetailView(
                                                    viewModel: TreatmentMedicationDetailViewModel(
                                                        medication: dose.medication,
                                                        medicationUseCases: viewModel.medicationUseCases,
                                                        profileUseCases: viewModel.profileUseCases,
                                                        treatmentUseCases: viewModel.treatmentUseCases
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
                AddTreatmentView(
                    viewModel: AddTreatmentViewModel(
                        treatmentUseCases: viewModel.treatmentUseCases,
                        profileUseCases: viewModel.profileUseCases,
                        medicationUseCases: viewModel.medicationUseCases
                    ),
                    showCloseButton: true
                )
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            .onAppear {
                viewModel.fetchData()
            }
            .onChange(of: showAddTreatment) { oldValue, isPresented in
                if !isPresented {
                    viewModel.fetchData()
                }
            }
            .alert(isPresented: $showTimeChangeConfirmation) {
                Alert(
                    title: Text("Update Future Doses?"),
                    message: Text("You changed the dose time by more than 20 minutes. Do you want to update all future doses based on this new time?"),
                    primaryButton: .default(Text("Update All Future Doses")) {
                        if let action = pendingDoseAction {
                            action()
                        }
                    },
                    secondaryButton: .cancel(Text("Just This One")) {
                        if let action = pendingDoseAction {
                            action()
                        }
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    
    // Helper methods for managing dose times
    private func doseKey(for dose: MedicationDose) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return "\(dose.medication.id)-\(formatter.string(from: dose.scheduledTime))"
    }
    
    private func getDoseTime(for dose: MedicationDose) -> Date {
        let key = doseKey(for: dose)
        return doseTimes[key] ?? Date() // Default to current time
    }
    
    private func setDoseTime(for dose: MedicationDose, time: Date) {
        let key = doseKey(for: dose)
        doseTimes[key] = time
    }
    
    // Helper methods for marking doses
    private func markDoseAsTaken(dose: MedicationDose) {
        let selectedTime = getDoseTime(for: dose)
        let timeDifference = abs(selectedTime.timeIntervalSince(dose.scheduledTime))
        let twentyMinutesInSeconds: TimeInterval = 20 * 60
        
        let logAction = {
            let log = DoseLog(
                medicationId: dose.medication.id,
                scheduledTime: dose.scheduledTime,
                takenTime: selectedTime,
                status: .taken
            )
            
            self.viewModel.medicationUseCases.logDose(log)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [viewModel] _ in
                    viewModel.fetchData()
                })
                .store(in: &self.cancellables)
        }
        
        // Only show confirmation if time difference is greater than 20 minutes
        if timeDifference > twentyMinutesInSeconds {
            pendingDoseAction = logAction
            showTimeChangeConfirmation = true
        } else {
            logAction()
        }
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

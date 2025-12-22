import SwiftUI
import Combine

struct AddTreatmentView: View {
    @StateObject var viewModel: AddTreatmentViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cancellableHolder = CancellableHolder()
    var showCloseButton: Bool = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                if viewModel.isEditing, let treatmentId = viewModel.editingTreatmentId {
                    // Details View Mode: Show Card
                    let displayTreatment = Treatment(
                        id: treatmentId,
                        name: viewModel.name,
                        startDate: viewModel.startDate,
                        endDate: nil,
                        profileId: viewModel.selectedProfileId
                    )
                    
                    let profile = viewModel.profiles.first(where: { $0.id == viewModel.selectedProfileId })
                    
                    TreatmentCard(
                        treatment: displayTreatment,
                        profile: profile,
                        medicationCount: viewModel.medications.count,
                        isCompleted: viewModel.isCompleted,
                        progress: viewModel.computedProgress
                    )
                } else {
                    // Add Mode: Show Form
                    CustomTextField(title: "Treatment Name", placeholder: "e.g. Post-Surgery Recovery", text: $viewModel.name)
                    
                    if viewModel.preselectedProfileId == nil {
                        profileSelectionView
                    }
                }
                    
                    if viewModel.isEditing, let treatmentId = viewModel.editingTreatmentId {
                        NavigationLink(destination: TreatmentDosageRegistryView(
                            viewModel: TreatmentDosageRegistryViewModel(
                                treatmentId: treatmentId,
                                medicationUseCases: viewModel.medicationUseCases
                            )
                        )) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primaryAction.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "list.clipboard.fill")
                                        .font(.caption)
                                        .foregroundColor(.primaryAction)
                                }
                                
                                Text("Dosage Registry")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.surface)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    medicationsSection
                    


                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(
                viewModel.isEditing ? "Treatment Details" : 
                (viewModel.preselectedProfileId != nil ? "For \(viewModel.profiles.first(where: { $0.id == viewModel.preselectedProfileId })?.name ?? "Profile")" : "New Treatment")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showCloseButton {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        NavigationLink(destination: EditTreatmentView(viewModel: viewModel)) {
                            Text("Edit")
                            .foregroundColor(.primaryAction)
                        }
                    } else {
                        Button(action: {
                            viewModel.saveTreatment()
                        }) {
                            Text("Save")
                            .foregroundColor(.primaryAction)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddMedication) {
                NavigationView {
                    AddMedicationView(viewModel: AddMedicationViewModel(
                        treatmentId: UUID(), // Temporary ID
                        medication: viewModel.editingMedication,
                        onSave: { medication in
                            if viewModel.editingMedication != nil {
                                viewModel.updateMedication(medication)
                            } else {
                                viewModel.addMedication(medication)
                            }
                        },
                        onDelete: { medication in
                            viewModel.deleteMedication(medication)
                        }
                    ))
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
            .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                viewModel.fetchProfiles()
                viewModel.fetchDoseLogs()
                if viewModel.isEditing, let treatmentId = viewModel.editingTreatmentId {
                    viewModel.fetchMedications(for: treatmentId)
                    
                    // Check if treatment still exists (in case it was deleted)
                    let subscription = viewModel.treatmentUseCases.getTreatments()
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { _ in }, receiveValue: { [weak viewModel] treatments in
                            if !treatments.contains(where: { $0.id == treatmentId }) {
                                // Treatment was deleted, dismiss this view
                                viewModel?.shouldDismiss = true
                            }
                        })
                    cancellableHolder.cancellables.insert(subscription)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var profileSelectionView: some View {
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
                            size: 60,
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
                                size: 60,
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
                        viewModel: AddProfileViewModel(profileUseCases: viewModel.profileUseCases),
                        showCloseButton: false
                    )) {
                        VStack {
                            Circle()
                                .fill(Color.surface)
                                .frame(width: 60, height: 60)
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
    }
    
    private var medicationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: {
                    viewModel.editingMedication = nil
                    viewModel.showAddMedication = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.primaryAction)
                }
            }
            
            if viewModel.medications.isEmpty {
                VStack {
                    Text("No medications added")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    Text("Tap the button to add a medication to this treatment.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    
                    Button(action: {
                        viewModel.editingMedication = nil
                        viewModel.showAddMedication = true
                    }) {
                        Text("+ Add Medication")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.primaryAction)
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.surface.opacity(0.5))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: Style.dash)
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                )
            } else {
                ForEach(viewModel.medications, id: \.id) { medication in
                    NavigationLink(destination: UnifiedMedicationDetailView(
                        viewModel: TreatmentMedicationDetailViewModel(
                            medication: medication,
                            medicationUseCases: viewModel.medicationUseCases,
                            profileUseCases: viewModel.profileUseCases,
                            treatmentUseCases: viewModel.treatmentUseCases
                        )
                    )) {
                        HStack(spacing: 16) {
                            // Medication Icon
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
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                Text("\(medication.dosage), Freq (hrs): \(medication.frequencyHours), Dur (days): \(medication.durationDays)")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                let status = viewModel.getMedicationStatus(medication: medication)
                                if status.isCompleted {
                                    Text("Completed")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray)
                                        .cornerRadius(4)
                                } else {
                                    Text("Upcoming Doses: \(status.upcomingCount)")
                                        .font(.caption2)
                                        .foregroundColor(.primaryAction)
                                }
                                
                                if medication.durationDays > 0 && !status.isCompleted {
                                    VStack(alignment: .leading, spacing: 2) {
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.gray.opacity(0.3)) // Darker background track
                                                    .frame(height: 4)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color(hex: medication.color.darkHex))
                                                    .frame(width: geometry.size.width * CGFloat(status.progress), height: 4)
                                            }
                                        }
                                        .frame(height: 4)
                                        
                                        Text("\(Int(status.progress * 100))% Completed")
                                            .font(.caption) // Larger font
                                            .fontWeight(.medium)
                                            .foregroundColor(.textSecondary)
                                            .scaleEffect(0.8, anchor: .leading)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                        .background(Color.surface)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct Style {
    static let dash = StrokeStyle(lineWidth: 1, dash: [5])
}

/// A simple utility class to hold Combine cancellables within a SwiftUI View
class CancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

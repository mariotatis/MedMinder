import SwiftUI
import Combine

struct TreatmentMedicationDetailView: View {
    @StateObject var viewModel: TreatmentMedicationDetailViewModel
    @State private var showEditMedication = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Medication Card (same as in treatment list)
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: viewModel.medication.color.darkHex))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: viewModel.medication.type.iconName)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.medication.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            if let profile = viewModel.profile {
                                Text("\(viewModel.medication.dosage), For \(profile.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text(viewModel.medication.dosage)
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            if viewModel.isCompleted {
                                Text("Completed")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Spacer()
                        
                        if let profile = viewModel.profile {
                            ProfileAvatar(profile: profile, size: 60)
                                .padding(.trailing, 4)
                        }
                    }
                    .padding()
                    .background(Color.surface)
                    .cornerRadius(16)
                    
                    // Custom Segmented Control with Badge
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 0) {
                            // Upcoming Segment
                            Button(action: {
                                viewModel.selectedSegment = 0
                            }) {
                                Text("Upcoming")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.selectedSegment == 0 ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedSegment == 0 ? Color.accentColor : Color.clear)
                                    .cornerRadius(8)
                            }
                            
                            // History Segment with Badge
                            Button(action: {
                                viewModel.selectedSegment = 1
                            }) {
                                HStack(spacing: 4) {
                                    Text("History")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    if viewModel.missedDoseCount > 0 {
                                        ZStack {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 20, height: 20)
                                            
                                            Text("\(viewModel.missedDoseCount)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .foregroundColor(viewModel.selectedSegment == 1 ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedSegment == 1 ? Color.accentColor : Color.clear)
                                .cornerRadius(8)
                            }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                        
                        // Content based on selected segment
                        if viewModel.selectedSegment == 0 {
                            // Upcoming Doses
                            if viewModel.upcomingDoses.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No upcoming doses.")
                                        .foregroundColor(.textSecondary)
                                }
                            } else {
                                ForEach(viewModel.upcomingDoses, id: \.self) { date in
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(.gray)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(date, style: .time)
                                                .font(.body)
                                                .foregroundColor(.textPrimary)
                                            Text(date, style: .date)
                                                .font(.subheadline)
                                                .foregroundColor(.textSecondary)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(12)
                                }
                            }
                        } else {
                            // History (all doses including missed)
                            if viewModel.allDoseLogs.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No doses recorded yet.")
                                        .foregroundColor(.textSecondary)
                                }
                            } else {
                                ForEach(viewModel.allDoseLogs) { log in
                                    HStack(alignment: .top, spacing: 12) {
                                        // Status Icon
                                        if log.status == .taken {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.green)
                                        } else if log.status == .skipped {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.orange)
                                        } else {
                                            // Pending - red for missed
                                            Image(systemName: "clock")
                                                .font(.title2)
                                                .foregroundColor(.red)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            // Status and Time
                                            if let takenTime = log.takenTime {
                                                Text("Taken at \(takenTime, style: .time)")
                                                    .font(.body)
                                                    .foregroundColor(.textPrimary)
                                            } else if log.status == .skipped {
                                                Text("Skipped")
                                                    .font(.body)
                                                    .foregroundColor(.orange)
                                            } else {
                                                // Missed dose
                                                HStack(spacing: 4) {
                                                    Text("Missed:")
                                                        .font(.body)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.red)
                                                    Text("\(log.scheduledTime, style: .time)")
                                                        .font(.body)
                                                        .foregroundColor(.textPrimary)
                                                }
                                            }
                                            
                                            // Date
                                            Text(log.scheduledTime, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Medication Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showEditMedication = true
                }) {
                    Text("Edit")
                    .foregroundColor(.primaryAction)
                }
            }
        }
        .sheet(isPresented: $showEditMedication) {
            NavigationView {
                MedicationEditWrapper(
                    medication: viewModel.medication,
                    medicationUseCases: viewModel.medicationUseCases
                )
            }
        }
        .onChange(of: showEditMedication) { isPresented in
            if !isPresented {
                // Sheet was dismissed, refresh data to check for deletion
                viewModel.refreshData()
            }
        }
        .onReceive(viewModel.$medicationWasDeleted) { wasDeleted in
            if wasDeleted {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}

// Wrapper to handle deletion callback
class CancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct MedicationEditWrapper: View {
    let medication: Medication
    let medicationUseCases: MedicationUseCases
    
    @StateObject private var viewModel: AddMedicationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(medication: Medication, medicationUseCases: MedicationUseCases) {
        self.medication = medication
        self.medicationUseCases = medicationUseCases
        _viewModel = StateObject(wrappedValue: AddMedicationViewModel(
            treatmentId: medication.treatmentId,
            medicationUseCases: medicationUseCases,
            medication: medication
        ))
    }
    
    var body: some View {
        AddMedicationView(viewModel: viewModel)
            .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}

import SwiftUI
import Combine

struct UnifiedMedicationDetailView: View {
    @StateObject var viewModel: TreatmentMedicationDetailViewModel
    @State private var showEditMedication = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Reusable Header
                    MedicationHeaderView(
                        medication: viewModel.medication,
                        profile: viewModel.profile,
                        isCompleted: viewModel.isCompleted,
                        progress: viewModel.progress
                    )
                    
                    if viewModel.isWithinActionWindow {
                        actionButtonsView
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        segmentedControl
                        
                        if viewModel.selectedSegment == 0 {
                            upcomingDosesList
                        } else {
                            historyDosesList
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
                AddMedicationView(viewModel: AddMedicationViewModel(
                    treatmentId: viewModel.medication.treatmentId,
                    medicationUseCases: viewModel.medicationUseCases,
                    medication: viewModel.medication
                ))
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onChange(of: showEditMedication) { oldValue, isPresented in
            if !isPresented {
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
        .alert(isPresented: $viewModel.showTimeChangeConfirmation) {
            Alert(
                title: Text("Update Future Doses?"),
                message: Text("You changed the dose time by more than 20 minutes. Do you want to update all future doses based on this new time?"),
                primaryButton: .default(Text("Update All Future Doses")) {
                    viewModel.logDoseAsTaken(updateFutureDoses: true)
                },
                secondaryButton: .cancel(Text("Just This One")) {
                    viewModel.logDoseAsTaken(updateFutureDoses: false)
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var actionButtonsView: some View {
        HStack(spacing: 8) {
            // Action buttons
            Button(action: viewModel.markAsTaken) {
                Text("Taken")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(viewModel.isDoseLogged ? Color.gray : Color.green)
                .cornerRadius(8)
            }
            .disabled(viewModel.isDoseLogged)
            
            Button(action: viewModel.markAsSkipped) {
                Text("Skipped")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(viewModel.isDoseLogged ? Color.gray : Color.orange)
                .cornerRadius(8)
            }
            .disabled(viewModel.isDoseLogged)
            
            // Time picker
            DatePicker("", selection: $viewModel.currentDoseTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .disabled(viewModel.isDoseLogged)
                .frame(maxWidth: 100)
        }
        .padding()
        .background(Color.surface)
        .cornerRadius(16)
    }
    
    private var segmentedControl: some View {
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
    }
    
    private var upcomingDosesList: some View {
        Group {
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
        }
    }
    
    private var historyDosesList: some View {
        Group {
            if viewModel.allDoseLogs.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No doses recorded yet.")
                        .foregroundColor(.textSecondary)
                }
            } else {
                ForEach(viewModel.allDoseLogs) { log in
                    historyRow(for: log)
                }
            }
        }
    }
    
    private func historyRow(for log: DoseLog) -> some View {
        DoseLogRow(
            medication: nil,
            log: log,
            onTaken: { takenTime in
                viewModel.markDoseAsTaken(scheduledTime: log.scheduledTime, takenTime: takenTime)
            },
            onSkipped: {
                viewModel.markDoseAsSkipped(scheduledTime: log.scheduledTime)
            }
        )
    }
}

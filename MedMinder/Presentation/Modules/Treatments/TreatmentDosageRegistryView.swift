import SwiftUI

struct TreatmentDosageRegistryView: View {
    @StateObject var viewModel: TreatmentDosageRegistryViewModel
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isCompleted {
                        HStack {
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray)
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Custom Segmented Control with Badge
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
                    .padding(.horizontal)
                    
                    // Content based on selected segment
                    if viewModel.selectedSegment == 0 {
                        // Upcoming Doses (future pending doses)
                        let upcomingDoses = viewModel.doseLogs
                            .filter { $0.doseLog.status == .pending && $0.doseLog.scheduledTime > Date() }
                            .sorted { $0.doseLog.scheduledTime < $1.doseLog.scheduledTime }
                        
                        if upcomingDoses.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No upcoming doses.")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                        } else {
                            ForEach(upcomingDoses) { item in
                                DoseLogRow(
                                    medication: item.medication,
                                    log: item.doseLog,
                                    onTaken: { takenTime in
                                        viewModel.markDoseAsTaken(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime, takenTime: takenTime)
                                    },
                                    onSkipped: {
                                        viewModel.markDoseAsSkipped(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime)
                                    }
                                )
                            }
                        }
                    } else {
                        // History (taken, skipped, and missed doses)
                        let historyDoses = viewModel.doseLogs.filter { $0.doseLog.status != .pending || $0.doseLog.scheduledTime <= Date() }
                        
                        if historyDoses.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No doses recorded yet.")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                        } else {
                            ForEach(historyDoses) { item in
                                DoseLogRow(
                                    medication: item.medication,
                                    log: item.doseLog,
                                    onTaken: { takenTime in
                                        viewModel.markDoseAsTaken(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime, takenTime: takenTime)
                                    },
                                    onSkipped: {
                                        viewModel.markDoseAsSkipped(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dosage Registry")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchDoseLogs()
        }
    }
}

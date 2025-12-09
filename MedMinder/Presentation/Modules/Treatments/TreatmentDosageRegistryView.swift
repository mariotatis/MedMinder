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
                        let upcomingDoses = viewModel.doseLogs.filter { $0.doseLog.status == .pending && $0.doseLog.scheduledTime > Date() }
                        
                        if upcomingDoses.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No upcoming doses.")
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                        } else {
                            ForEach(upcomingDoses) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(item.medication.name), \(item.medication.dosage)")
                                            .font(.headline)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text("Scheduled for \(item.doseLog.scheduledTime, style: .time)")
                                            .font(.body)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text(item.doseLog.scheduledTime, style: .date)
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
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        // Status Icon
                                        if item.doseLog.status == .taken {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if item.doseLog.status == .skipped {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.orange)
                                        } else if item.doseLog.status == .pending {
                                            // Pending - red for missed, grey for upcoming
                                            Image(systemName: "clock")
                                                .foregroundColor(item.doseLog.scheduledTime < Date() ? .red : .gray)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            // Medication Name and Dosage
                                            Text("\(item.medication.name), \(item.medication.dosage)")
                                                .font(.headline)
                                                .foregroundColor(.textPrimary)
                                            
                                            // Status and Time
                                            if let takenTime = item.doseLog.takenTime {
                                                Text("Taken at \(takenTime, style: .time)")
                                                    .font(.body)
                                                    .foregroundColor(.textPrimary)
                                            } else if item.doseLog.status == .skipped {
                                                Text("Skipped dose at \(item.doseLog.scheduledTime, style: .time)")
                                                    .font(.body)
                                                    .foregroundColor(.orange)
                                            } else if item.doseLog.status == .pending {
                                                // Pending dose - check if missed (past) or upcoming (future)
                                                if item.doseLog.scheduledTime < Date() {
                                                    // Missed dose
                                                    HStack(spacing: 4) {
                                                        Text("Missed:")
                                                            .font(.body)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.red)
                                                        Text("\(item.doseLog.scheduledTime, style: .time)")
                                                            .font(.body)
                                                            .foregroundColor(.textPrimary)
                                                    }
                                                } else {
                                                    // Upcoming dose
                                                    Text("Scheduled for \(item.doseLog.scheduledTime, style: .time)")
                                                        .font(.body)
                                                        .foregroundColor(.textPrimary)
                                                }
                                            }
                                            
                                            // Date
                                            Text(item.doseLog.scheduledTime, style: .date)
                                                .font(.subheadline)
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    // Action buttons for missed doses (only show for past doses)
                                    if item.doseLog.status == .pending && item.doseLog.scheduledTime < Date() {
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                viewModel.markDoseAsTaken(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime)
                                            }) {
                                                Text("Mark as Taken")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.green)
                                                    .cornerRadius(8)
                                            }
                                            
                                            Button(action: {
                                                viewModel.markDoseAsSkipped(medicationId: item.medication.id, scheduledTime: item.doseLog.scheduledTime)
                                            }) {
                                                Text("Mark as Skipped")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.orange)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.surface)
                                .cornerRadius(12)
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

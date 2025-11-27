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
                    
                    if viewModel.doseLogs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No doses recorded yet.")
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                    } else {
                        ForEach(viewModel.doseLogs) { item in
                            HStack(alignment: .top, spacing: 12) {
                                // Status Icon
                                if item.doseLog.status == .taken {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else if item.doseLog.status == .skipped {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                } else if item.doseLog.status == .pending {
                                    Image(systemName: "clock")
                                        .foregroundColor(.textSecondary)
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
                                        Text("Scheduled for \(item.doseLog.scheduledTime, style: .time)")
                                            .font(.body)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    // Date
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

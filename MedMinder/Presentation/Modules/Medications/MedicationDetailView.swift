import SwiftUI

struct MedicationDetailView: View {
    @StateObject var viewModel: MedicationDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
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
                    
                    // Dose Time Input - only show for current/past doses
                    if !viewModel.isFutureDose {
                        HStack {
                            Text("Dose Time:")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            DatePicker("", selection: $viewModel.currentDoseTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(CompactDatePickerStyle())
                                .labelsHidden()
                                .disabled(viewModel.isDoseLogged)
                        }
                        .padding()
                        .background(Color.surface)
                        .cornerRadius(16)
                    }
                    
                    // Action Buttons - only show for current/past doses
                    if !viewModel.isFutureDose {
                        HStack(spacing: 12) {
                            Button(action: viewModel.markAsTaken) {
                                Text("Mark as Taken")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.isDoseLogged ? Color.gray : Color.primaryAction)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isDoseLogged)
                            
                            Button(action: viewModel.markAsSkipped) {
                                Text("Skipped")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.isDoseLogged ? Color.gray : Color.orange)
                                    .cornerRadius(12)
                            }
                            .disabled(viewModel.isDoseLogged)
                        }
                    }
                    
                    // Upcoming Doses
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Doses")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        ForEach(viewModel.upcomingDoses, id: \.self) { date in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.textSecondary)
                                Text(date, style: .time)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                Text(date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color.surface)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dosage Registry")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.textPrimary)
                        
                        if viewModel.doseLogs.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No doses recorded yet.")
                                    .foregroundColor(.textSecondary)
                            }
                        } else {
                            ForEach(viewModel.doseLogs) { log in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        if log.status == .taken {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else if log.status == .skipped {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.orange)
                                        } else {
                                            // Pending - red for missed, grey for upcoming
                                            Image(systemName: "clock")
                                                .foregroundColor(log.scheduledTime < Date() ? .red : .gray)
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            if let takenTime = log.takenTime {
                                                Text("Taken at \(takenTime, style: .time)")
                                                    .font(.body)
                                                    .foregroundColor(.textPrimary)
                                                Text(takenTime, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.textSecondary)
                                            } else if log.status == .skipped {
                                                Text("Skipped dose at \(log.scheduledTime, style: .time)")
                                                    .font(.body)
                                                    .foregroundColor(.orange)
                                                Text(log.scheduledTime, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.textSecondary)
                                            } else {
                                                // Pending dose - check if missed (past) or upcoming (future)
                                                if log.scheduledTime < Date() {
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
                                                } else {
                                                    // Upcoming dose
                                                    Text("Scheduled for \(log.scheduledTime, style: .time)")
                                                        .font(.body)
                                                        .foregroundColor(.textPrimary)
                                                }
                                                Text(log.scheduledTime, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.textSecondary)
                                            }
                                        }
                                        Spacer()
                                    }
                                    
                                    // Action buttons for missed doses (only show for past doses)
                                    if log.status == .pending && log.scheduledTime < Date() {
                                        HStack(spacing: 8) {
                                            Button(action: {
                                                viewModel.markDoseAsTaken(scheduledTime: log.scheduledTime)
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
                                                viewModel.markDoseAsSkipped(scheduledTime: log.scheduledTime)
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
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Medication Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $viewModel.showTimeChangeConfirmation) {
            Alert(
                title: Text("Update Future Doses?"),
                message: Text("You changed the dose time. Do you want to update all future doses based on this new time?"),
                primaryButton: .default(Text("Update All Future Doses")) {
                    viewModel.logDoseAsTaken(updateFutureDoses: true)
                },
                secondaryButton: .cancel(Text("Just This One")) {
                    viewModel.logDoseAsTaken(updateFutureDoses: false)
                }
            )
        }
    }
}

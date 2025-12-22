import SwiftUI

struct AddMedicationView: View {
    @StateObject var viewModel: AddMedicationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showDeleteConfirmation = false
    
    enum Field: Hashable {
        case name, dosage, frequency, duration
    }
    
    @FocusState private var focusedField: Field?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 0) {
                        CustomFocusedTextField(title: "Medication Name", placeholder: "Ibuprofen", text: $viewModel.name, focusState: $focusedField, focusValue: Field.name)
                            .onSubmit {
                                viewModel.searchResults = []
                                focusedField = .dosage
                            }
                        
                        if !viewModel.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(viewModel.searchResults) { result in
                                            Button(action: {
                                                viewModel.selectSearchResult(result)
                                                focusedField = .dosage
                                            }) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(result.generic_name ?? "")
                                                        .font(.body)
                                                        .foregroundColor(.textPrimary)
                                                        .multilineTextAlignment(.leading)
                                                    Text(result.brand_name ?? "")
                                                        .font(.subheadline) // Slightly bigger than .caption
                                                        .foregroundColor(.textSecondary)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding()
                                                .background(Color.surface)
                                            }
                                            Divider()
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(Color.surface)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            .zIndex(1)
                        }
                    }
                    
                    CustomFocusedTextField(title: "Dosage", placeholder: "e.g. 500 mg", text: $viewModel.dosage, focusState: $focusedField, focusValue: Field.dosage)
                        .onSubmit {
                            focusedField = .frequency
                        }
                    
                    // Frequency, Duration, Initial Time in one row
                    HStack(spacing: 12) {
                        CustomFocusedTextField(title: "Freq (Hrs)", placeholder: "8", text: $viewModel.frequencyHours, focusState: $focusedField, focusValue: Field.frequency)
                            .keyboardType(.numberPad)
                            .onSubmit {
                                focusedField = .duration
                            }
                        
                        CustomFocusedTextField(title: "Dur (Days)", placeholder: "14", text: $viewModel.durationDays, focusState: $focusedField, focusValue: Field.duration)
                            .keyboardType(.numberPad)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start Time")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            IntervalDatePicker(selection: $viewModel.initialTime, minuteInterval: 15, displayedComponents: .hourAndMinute)
                                .frame(height: 44)
                                .background(Color.surface)
                                .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(MedicationType.allCases) { type in
                                VStack {
                                    Image(systemName: type.iconName)
                                        .font(.system(size: 32))
                                        .padding(.bottom, 4)
                                        .foregroundColor(viewModel.selectedType == type ? .white : .textPrimary)
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(viewModel.selectedType == type ? .white : .textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    viewModel.selectedType == type ? 
                                    Color(hex: viewModel.selectedColor.darkHex) : 
                                    Color.surface
                                )
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.selectedType == type ? Color(hex: viewModel.selectedColor.darkHex) : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    viewModel.selectedType = type
                                    hideKeyboard()
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Theme")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(MedicationColor.allCases) { color in
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: color.darkHex))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: viewModel.selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                                        
                                        if viewModel.selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                        }
                                    }
                                    .onTapGesture {
                                        viewModel.selectedColor = color
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.isEditing {
                        Button(action: { showDeleteConfirmation = true }) {
                            Text("Remove Medication")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .alert(isPresented: $showDeleteConfirmation) {
                            Alert(
                                title: Text("Delete Medication"),
                                message: Text("Are you sure you want to delete this medication?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    viewModel.deleteMedication()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Medication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.saveMedication) {
                    Text("Save")
                    .foregroundColor(.primaryAction)
                }
            }
        }.onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


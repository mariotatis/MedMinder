import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let medicationUseCases: MedicationUseCases
    @State private var currentQuote: String = HealthQuotes.random()
    @AppStorage("areRemindersEnabled") private var areRemindersEnabled = false
    @AppStorage("actionWindowHours") private var actionWindowHours = 4.0 // Default to 4 hours
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quote Card
                        HStack(spacing: 16) {
                            // App Icon
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Text("\"\(currentQuote)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundColor(.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        .padding()                        
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Links List
                        VStack(spacing: 0) {
                            // Reminders Toggle
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.primaryAction.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "bell.fill")
                                        .font(.caption)
                                        .foregroundColor(.primaryAction)
                                }
                                
                                Text("Reminders")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $areRemindersEnabled)
                                    .labelsHidden()
                                    .onChange(of: areRemindersEnabled) { oldValue, enabled in
                                        if enabled {
                                            NotificationService.shared.requestAuthorization { granted in
                                                if granted {
                                                    medicationUseCases.rescheduleAllReminders()
                                                } else {
                                                    DispatchQueue.main.async {
                                                        areRemindersEnabled = false
                                                    }
                                                }
                                            }
                                        } else {
                                            NotificationService.shared.cancelAll()
                                        }
                                    }
                            }
                            .padding()
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            SettingsLinkRow(title: "MedMinder Pro", icon: "star.fill", iconColor: .yellow)
                        }
                        .background(Color.surface)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Appearance
                        VStack(spacing: 0) {
                             HStack {
                                 ZStack {
                                     RoundedRectangle(cornerRadius: 8)
                                         .fill(Color.primaryAction.opacity(0.1))
                                         .frame(width: 32, height: 32)
                                     
                                     Image(systemName: "sun.max.fill")
                                         .font(.caption)
                                         .foregroundColor(.primaryAction)
                                 }
                                 
                                 Text("Theme")
                                     .font(.body)
                                     .foregroundColor(.textPrimary)
                                 
                                 Spacer()
                                 
                                 Picker("Theme", selection: $themeManager.currentTheme) {
                                     ForEach(AppTheme.allCases) { theme in
                                         Text(theme.displayName).tag(theme)
                                     }
                                 }
                                 .pickerStyle(MenuPickerStyle())
                             }
                             .padding()
                        }
                        .background(Color.surface)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Action Window
                        VStack(spacing: 0) {
                             HStack {
                                 ZStack {
                                     RoundedRectangle(cornerRadius: 8)
                                         .fill(Color.orange.opacity(0.1))
                                         .frame(width: 32, height: 32)
                                     
                                     Image(systemName: "clock.badge.checkmark.fill")
                                         .font(.caption)
                                         .foregroundColor(.orange)
                                 }
                                 
                                 VStack(alignment: .leading, spacing: 2) {
                                     Text("Medication Lead Time")
                                         .font(.body)
                                         .foregroundColor(.textPrimary)
                                     Text("Show actions before schduled time")
                                         .font(.caption2)
                                         .foregroundColor(.textSecondary)
                                 }
                                 
                                 Spacer()
                                 
                                 Picker("Hours", selection: $actionWindowHours) {
                                     Text("30 min").tag(0.5)
                                     Text("1 hour").tag(1.0)
                                     Text("2 hours").tag(2.0)
                                     Text("3 hours").tag(3.0)
                                     Text("4 hours").tag(4.0)
                                 }
                                 .pickerStyle(MenuPickerStyle())
                             }
                             .padding()
                        }
                        .background(Color.surface)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("MedMinder")
            .onAppear {
                currentQuote = HealthQuotes.random()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsLinkRow: View {
    let title: String
    let icon: String
    var iconColor: Color = .primaryAction
    
    var body: some View {
        Button(action: {
            // No action for now
        }) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
    }
}

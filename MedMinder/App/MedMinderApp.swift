import SwiftUI

@main
struct MedMinderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = AppContainer()
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                HomeView(
                    viewModel: HomeViewModel(
                        medicationUseCases: container.medicationUseCases,
                        profileUseCases: container.profileUseCases,
                        treatmentUseCases: container.treatmentUseCases
                    )
                )
                .tabItem {
                    Label("Upcoming", systemImage: "pill.fill")
                }
                .tag(0)
                
                TreatmentListView(
                    viewModel: TreatmentListViewModel(
                        treatmentUseCases: container.treatmentUseCases,
                        profileUseCases: container.profileUseCases,
                        medicationUseCases: container.medicationUseCases
                    ),
                    treatmentUseCases: container.treatmentUseCases,
                    profileUseCases: container.profileUseCases,
                    medicationUseCases: container.medicationUseCases
                )
                .tabItem {
                    Label("Treatments", systemImage: "list.clipboard.fill")
                }
                .tag(1)
                
                ProfileListView(
                    viewModel: ProfileListViewModel(profileUseCases: container.profileUseCases),
                    profileUseCases: container.profileUseCases,
                    treatmentUseCases: container.treatmentUseCases,
                    medicationUseCases: container.medicationUseCases
                )
                .tabItem {
                    Label("Family", systemImage: "person.2.fill")
                }
                .tag(2)
                
                SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(3)
                
            }
            .accentColor(.primaryAction)
            //.preferredColorScheme(.dark) // Force dark mode as per design
            .onAppear {
                container.syncReminders()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // This method is called when a notification is delivered to a foreground app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification as a banner and play sound even if the app is open
        completionHandler([.banner, .sound, .list])
    }
}

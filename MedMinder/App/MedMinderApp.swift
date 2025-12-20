import SwiftUI

@main
struct MedMinderApp: App {
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = AppContainer()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @State private var showAddProfileSheet = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1) // Ensure it stays on top during transition
                } else if !hasOnboarded {
                    OnboardingView(isOnboardingCompleted: $hasOnboarded) {
                        showAddProfileSheet = true
                    }
                    .transition(.opacity)
                } else {
                    mainAppContent
                        .transition(.opacity)
                }
            }
        }
    }
    
    var mainAppContent: some View {
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
        .accentColor(.primaryAction)
        .preferredColorScheme(themeManager.currentTheme == .system ? nil : (themeManager.currentTheme == .dark ? .dark : .light))
        .environmentObject(themeManager)
        .onAppear {
            container.syncReminders()
        }
        .sheet(isPresented: $showAddProfileSheet) {
            NavigationView {
                AddProfileView(
                    viewModel: AddProfileViewModel(profileUseCases: container.profileUseCases),
                    isOnboarding: true
                )
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

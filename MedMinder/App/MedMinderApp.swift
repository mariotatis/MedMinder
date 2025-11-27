import SwiftUI

@main
struct MedMinderApp: App {
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
                    Label("Home", systemImage: "heart.fill")
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
                    Label("Profiles", systemImage: "person.2.fill")
                }
                .tag(2)
            }
            .accentColor(.primaryAction)
            //.preferredColorScheme(.dark) // Force dark mode as per design
        }
    }
}

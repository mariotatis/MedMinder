import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "Auto (System)"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("appTheme") var currentTheme: AppTheme = .dark
    
    private init() {}
}

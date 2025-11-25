import Foundation

enum MedicationType: String, Codable, CaseIterable, Identifiable {
    case pills = "Pills"
    case capsule = "Capsule"
    case drops = "Drops"
    case cream = "Cream"
    case lotion = "Lotion"
    case inhaler = "Inhaler"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .pills: return "pill.fill"
        case .capsule: return "capsule.fill"
        case .drops: return "eyedropper.halffull"
        case .cream: return "waterbottle.fill"
        case .lotion: return "cross.vial"
        case .inhaler: return "inhaler"
        }
    }
}

enum MedicationColor: String, Codable, CaseIterable, Identifiable {
    case red, blue, green, yellow, purple, orange, teal, pink
    
    var id: String { rawValue }
    
    // Hex codes for light background (pastels)
    var lightHex: String {
        switch self {
        case .red: return "#FFEBEE"
        case .blue: return "#E3F2FD"
        case .green: return "#E8F5E9"
        case .yellow: return "#FFFDE7"
        case .purple: return "#F3E5F5"
        case .orange: return "#FFF3E0"
        case .teal: return "#E0F2F1"
        case .pink: return "#FCE4EC"
        }
    }
    
    // Hex codes for dark icon/text
    var darkHex: String {
        switch self {
        case .red: return "#C62828"
        case .blue: return "#1565C0"
        case .green: return "#2E7D32"
        case .yellow: return "#F9A825"
        case .purple: return "#6A1B9A"
        case .orange: return "#EF6C00"
        case .teal: return "#00695C"
        case .pink: return "#AD1457"
        }
    }
}

struct Medication: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dosage: String
    var frequencyHours: Int
    var durationDays: Int
    var type: MedicationType
    var initialTime: Date
    var color: MedicationColor
    var treatmentId: UUID
    
    init(id: UUID = UUID(), name: String, dosage: String, frequencyHours: Int, durationDays: Int, type: MedicationType, initialTime: Date, color: MedicationColor, treatmentId: UUID) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.frequencyHours = frequencyHours
        self.durationDays = durationDays
        self.type = type
        self.initialTime = initialTime
        self.color = color
        self.treatmentId = treatmentId
    }
}

struct DoseLog: Identifiable, Codable, Equatable {
    let id: UUID
    var medicationId: UUID
    var scheduledTime: Date
    var takenTime: Date?
    var status: DoseStatus
    
    enum DoseStatus: String, Codable {
        case pending
        case taken
        case skipped
    }
    
    init(id: UUID = UUID(), medicationId: UUID, scheduledTime: Date, takenTime: Date? = nil, status: DoseStatus = .pending) {
        self.id = id
        self.medicationId = medicationId
        self.scheduledTime = scheduledTime
        self.takenTime = takenTime
        self.status = status
    }
}

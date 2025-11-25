import Foundation

struct Treatment: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date?
    var profileId: UUID?
    
    init(id: UUID = UUID(), name: String, startDate: Date = Date(), endDate: Date? = nil, profileId: UUID? = nil) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.profileId = profileId
    }
}

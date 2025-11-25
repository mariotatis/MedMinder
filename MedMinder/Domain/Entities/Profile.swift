import Foundation

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var age: Int
    var imageName: String?
    
    init(id: UUID = UUID(), name: String, age: Int, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.age = age
        self.imageName = imageName
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        if let first = components.first?.first {
            if let last = components.last?.first, components.count > 1 {
                return "\(first)\(last)".uppercased()
            }
            return "\(first)".uppercased()
        }
        return "?"
    }
}

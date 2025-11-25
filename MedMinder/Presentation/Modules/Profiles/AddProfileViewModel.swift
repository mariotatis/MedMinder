import Foundation
import Combine
import UIKit

class AddProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: String = ""
    @Published var selectedImage: UIImage?
    @Published var cropperImage: UIImage?
    @Published var shouldDismiss: Bool = false
    
    private let profileUseCases: ProfileUseCases
    private var cancellables = Set<AnyCancellable>()
    private var editingProfileId: UUID?
    private var currentImageName: String?
    private var onSave: ((Profile?) -> Void)?
    
    var isEditing: Bool {
        return editingProfileId != nil
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let first = components.first?.first.map { String($0) } ?? ""
        let last = components.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
    
    init(profileUseCases: ProfileUseCases, profile: Profile? = nil, onSave: ((Profile?) -> Void)? = nil) {
        self.profileUseCases = profileUseCases
        self.onSave = onSave
        if let profile = profile {
            self.name = profile.name
            self.age = profile.age > 0 ? "\(profile.age)" : ""
            self.editingProfileId = profile.id
            self.currentImageName = profile.imageName
            if let imageName = profile.imageName {
                self.selectedImage = loadImage(named: imageName)
            }
        }
    }
    
    func deleteProfile() {
        guard let id = editingProfileId else { return }
        
        profileUseCases.deleteProfile(id: id)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?.onSave?(nil)
                self?.shouldDismiss = true
            })
            .store(in: &cancellables)
    }
    
    func saveProfile() {
        guard !name.isEmpty else { return }
        
        let ageInt = Int(age) ?? 0
        
        var imageName = currentImageName
        if let selectedImage = selectedImage {
            imageName = saveImage(selectedImage)
        }
        
        if let id = editingProfileId {
            let profile = Profile(id: id, name: name, age: ageInt, imageName: imageName)
            profileUseCases.updateProfile(profile)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                    self?.onSave?(profile)
                    self?.shouldDismiss = true
                })
                .store(in: &cancellables)
        } else {
            let profile = Profile(id: UUID(), name: name, age: ageInt, imageName: imageName)
            profileUseCases.addProfile(profile)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                    self?.onSave?(profile)
                    self?.shouldDismiss = true
                })
                .store(in: &cancellables)
        }
    }
    
    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: url)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func loadImage(named filename: String) -> UIImage? {
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

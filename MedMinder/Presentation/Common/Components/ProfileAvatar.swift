import SwiftUI

struct ProfileAvatar: View {
    let profile: Profile?
    let size: CGFloat
    var showBorder: Bool = false
    var isSelected: Bool = false
    
    var body: some View {
        ZStack {
            if let profile = profile {
                if let imageName = profile.imageName,
                   let image = loadImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: size, height: size)
                    
                    Text(profile.initials)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                // Temp / No Profile
                Circle()
                    .fill(Color.gray)
                    .frame(width: size, height: size)
                
                Text("?")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            }
            
            if showBorder {
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    .frame(width: size, height: size)
            }
        }
    }
    
    private func loadImage(named filename: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
}

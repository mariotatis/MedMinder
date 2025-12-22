import SwiftUI

struct AppBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.background.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "4CAF50").opacity(colorScheme == .dark ? 0.15 : 0.1), location: 0),
                            .init(color: Color(hex: "F44336").opacity(colorScheme == .dark ? 0.15 : 0.1), location: 0.6),
                            .init(color: Color.background.opacity(0), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.75)
                    
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct AppBackground_Previews: PreviewProvider {
    static var previews: some View {
        AppBackground()
            .preferredColorScheme(.dark)
        AppBackground()
            .preferredColorScheme(.light)
    }
}

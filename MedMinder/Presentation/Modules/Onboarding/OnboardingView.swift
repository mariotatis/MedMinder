import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    var onFinish: () -> Void
    
    @State private var currentPage = 0
    
    let slides: [OnboardingSlide] = [
        OnboardingSlide(
            title: "Welcome to MedMinder",
            description: "Your personal health companion. Add family members, manage treatments, and never miss a dose again.",
            imageName: "heart.text.square.fill"
        ),
        OnboardingSlide(
            title: "Track & Remind",
            description: "Easily log medications, set up custom schedules, and receive timely push notifications so you stay on track with your health.",
            imageName: "pill.fill"
        ),
        OnboardingSlide(
            title: "Get Started",
            description: "Let's get you set up! Create your first profile to start managing your health journey personalized just for you.",
            imageName: "person.crop.circle.badge.plus"
        )
    ]
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        finishOnboarding()
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: slides[index].imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.primaryAction)
                                .padding(.bottom, 20)
                            
                            Text(slides[index].title)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.textPrimary)
                            
                            Text(slides[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.textSecondary)
                                .padding(.horizontal, 32)
                                .lineSpacing(4)
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < slides.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        finishOnboarding(shouldShowAddProfile: true)
                    }
                }) {
                    Text(currentPage < slides.count - 1 ? "Next" : "Create Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryAction)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func finishOnboarding(shouldShowAddProfile: Bool = false) {
        isOnboardingCompleted = true
        if shouldShowAddProfile {
            onFinish()
        }
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingCompleted: .constant(false), onFinish: {})
    }
}

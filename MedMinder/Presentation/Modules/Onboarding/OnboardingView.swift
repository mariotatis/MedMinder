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
    @Namespace private var iconNamespace
    @State private var animateIcon = false
    @State private var appear = false
    @State private var isDragging = false
    
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
                            
                            ZStack {
                                // Soft halo glow background
                                Circle()
                                    .fill(Color.primaryAction.opacity(0.12))
                                    .frame(width: 220, height: 220)
                                    .scaleEffect(isDragging ? 1 : (appear ? 1 : 0.8))
                                    .blur(radius: isDragging ? 0 : (appear ? 0 : 6))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appear)

                                Image(systemName: slides[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.primaryAction)
                                    .matchedGeometryEffect(id: "icon", in: iconNamespace)
                                    .scaleEffect(isDragging ? 1.0 : (animateIcon ? 1.06 : 1.0))
                                    .rotationEffect(.degrees(isDragging ? 0 : (animateIcon ? 3 : 0)))
                                    .shadow(color: Color.primaryAction.opacity(0.25), radius: 10, x: 0, y: 8)
                                    .animation(.interpolatingSpring(stiffness: 140, damping: 16), value: animateIcon)
                            }
                            .padding(.bottom, 20)
                            
                            VStack(spacing: 12) {
                                Text(slides[index].title)
                                    .font(.system(size: 28, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.textPrimary)
                                    .opacity(isDragging ? 1 : (appear ? 1 : 0))
                                    .offset(y: isDragging ? 0 : (appear ? 0 : 10))
                                    .animation(.easeOut(duration: 0.35).delay(0.05), value: appear)

                                Text(slides[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 32)
                                    .lineSpacing(4)
                                    .opacity(isDragging ? 1 : (appear ? 1 : 0))
                                    .offset(y: isDragging ? 0 : (appear ? 0 : 10))
                                    .animation(.easeOut(duration: 0.35).delay(0.12), value: appear)
                            }
                            
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .highPriorityGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { _ in
                            if !isDragging { isDragging = true }
                        }
                        .onEnded { _ in
                            // Defer turning off dragging slightly to avoid race with page settle
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isDragging = false
                            }
                        }
                )
                .transaction { txn in
                    // Prevent implicit animations during interactive paging to avoid jitter
                    if isDragging {
                        txn.animation = nil
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Decorative, tappable page dots (primaryAction color)
                HStack(spacing: 10) {
                    ForEach(0..<slides.count, id: \.self) { dot in
                        Button(action: {
                            navigateWithNextAnimation(to: dot)
                        }) {
                            Circle()
                                .fill(dot == currentPage ? Color.primaryAction : Color.primaryAction.opacity(0.25))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle().stroke(Color.primaryAction.opacity(0.15), lineWidth: dot == currentPage ? 0 : 1)
                                )
                                .scaleEffect(dot == currentPage ? 1.15 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Page selector")
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        animateIcon.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animateIcon.toggle()
                    }
                    if currentPage < slides.count - 1 {
                        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
                            currentPage += 1
                        }
                        // Reset appear for next page and re-animate in
                        appear = false
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                                appear = true
                            }
                        }
                    } else {
                        // Finishing flourish
                        finishWithSparkle()
                    }
                }) {
                    Text(currentPage < slides.count - 1 ? "Next" : "Create Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [Color.primaryAction, Color.primaryAction.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                        .shadow(color: Color.primaryAction.opacity(0.25), radius: 12, x: 0, y: 8)
                        .scaleEffect(animateIcon ? 0.98 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: animateIcon)
                }
            }
            .onAppear {
                appear = true
            }
            .onChange(of: currentPage) { _, _ in
                guard !isDragging else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        animateIcon = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            animateIcon = false
                        }
                    }
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
    
    private func navigateWithNextAnimation(to index: Int) {
        guard index >= 0 && index < slides.count else { return }
        // Replicate the Next button's subtle press pulse and appear sequence
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animateIcon.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateIcon.toggle()
        }
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.85)) {
            currentPage = index
        }
        // Reset appear for target page and re-animate in
        appear = false
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                appear = true
            }
        }
    }
    
    private func finishWithSparkle() {
        // A small celebratory finish before moving on
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            animateIcon = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            animateIcon = false
            finishOnboarding(shouldShowAddProfile: true)
        }
    }
}

// Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingCompleted: .constant(false), onFinish: {})
    }
}


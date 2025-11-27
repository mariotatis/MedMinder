import Foundation

struct HealthQuotes {
    static let all: [String] = [
        "The greatest wealth is health.",
        "Let food be your medicine and medicine your food.",
        "Rest well, rise early, and care for your health daily.",
        "We seldom value health until illness reminds us.",
        "Care for your body, it is the only home you truly live in.",
        "A healthy outside begins with a healthy inside.",
        "Good health is a duty, for mind and body work as one.",
        "Happiness is one of the purest forms of health.",
        "Invest in your health, it will always bring the best returns.",
        "Consistency turns small healthy habits into lifelong strength.",
        "Your future self will thank you for the care you give today.",
        "Health grows with every mindful choice.",
        "Every dose, every step, every routine moves you forward.",
        "Well-being is a journey, not a finish line.",
        "Small daily actions create big changes over time.",
        "Take the time to nurture your body, it is working hard for you.",
        "Progress is built on patience and steady routines.",
        "Good health starts with simple acts repeated often.",
        "A clear mind begins with a cared-for body.",
        "Healing is not a race, honor your own pace.",
        "Healthy habits are gifts you give yourself.",
        "Your body whispers before it ever has to shout. Listen gently.",
        "You deserve the care you give to others.",
        "Balance, rest, and nourishment are powerful medicine.",
        "Wellness is created by the choices you repeat, not the ones you make once.",
        "Take a breath. Take your time. Take care of you.",
        "Health is built in ordinary moments done with intention.",
        "Caring for yourself is a form of strength, not indulgence.",
        "Your wellness journey is unique. Honor it, trust it, and keep going."
    ]
    
    static func random() -> String {
        all.randomElement() ?? "The greatest wealth is health."
    }
}
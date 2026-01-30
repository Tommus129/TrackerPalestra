import SwiftUI

extension Color {
    static let customBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let acidGreen = Color(red: 0.75, green: 1.0, blue: 0.0)
    static let deepPurple = Color(red: 0.5, green: 0.0, blue: 1.0)
    static let softPurple = Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.15)
    
    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Punto 3: Glow Variabile (Pulsante)
struct PulsingNeonModifier: ViewModifier {
    @State private var pulse: CGFloat = 1.0
    var color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4 * pulse), radius: 10 * pulse)
            .shadow(color: color.opacity(0.2 * pulse), radius: 20 * pulse)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    pulse = 1.4
                }
            }
    }
}

// MARK: - Punto 4: Animated Border (Bordo Rotante)
struct AnimatedCyberBorder: ViewModifier {
    @State private var rotation: Double = 0
    var colors: [Color] = [.acidGreen, .deepPurple, .acidGreen]

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: colors), center: .center, angle: .degrees(rotation)),
                        lineWidth: 2
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Punto 6: Micro-interazioni (Effetto Pressione)
struct CyberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension View {
    func pulsingNeon(color: Color = .acidGreen) -> some View {
        modifier(PulsingNeonModifier(color: color))
    }
    
    func animatedBorder() -> some View {
        modifier(AnimatedCyberBorder())
    }
    
    func glassStyle() -> some View {
        self.background(.ultraThinMaterial)
            .background(Color.cardGradient)
            .cornerRadius(15)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

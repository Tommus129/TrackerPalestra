import SwiftUI

extension Color {
    static let customBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let acidGreen   = Color(red: 0.75, green: 1.0, blue: 0.0)
    static let deepPurple  = Color(red: 0.5,  green: 0.0, blue: 1.0)

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Glow statico (una sola shadow, nessuna animazione infinita)
struct SubtleGlowModifier: ViewModifier {
    var color: Color
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.45), radius: 12)
    }
}

// MARK: - Bordo statico con gradient (zero animazioni per card)
// Sostituisce AnimatedCyberBorder che avviava un'animazione .repeatForever
// per ogni istanza, causando N thread GPU in parallelo sulla HomeView.
struct StaticGradientBorder: ViewModifier {
    var colors: [Color] = [.acidGreen, .deepPurple, .acidGreen]
    var cornerRadius: CGFloat = 15
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

// MARK: - Bottone (effetto pressione)
struct CyberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Theme
struct Theme {
    static let backgroundColor    = Color.customBlack
    static let primaryColor       = Color.acidGreen
    static let secondaryColor     = Color.deepPurple
    static let cardColor          = Color.white.opacity(0.05)
    static let textColor          = Color.white
    static let secondaryTextColor = Color.white.opacity(0.6)
}

extension View {
    /// Glow statico: una sola shadow, nessun loop.
    func subtleGlow(color: Color = .acidGreen) -> some View {
        modifier(SubtleGlowModifier(color: color))
    }

    /// Bordo con gradient statico: zero animazioni per istanza.
    func staticBorder(
        colors: [Color] = [.acidGreen, .deepPurple, .acidGreen],
        cornerRadius: CGFloat = 15,
        lineWidth: CGFloat = 1.5
    ) -> some View {
        modifier(StaticGradientBorder(colors: colors, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }

    func glassStyle() -> some View {
        self.background(.ultraThinMaterial)
            .background(Color.cardGradient)
            .cornerRadius(15)
    }
}

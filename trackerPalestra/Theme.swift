import SwiftUI

extension Color {
    static let customBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let acidGreen = Color(red: 0.75, green: 1.0, blue: 0.0)
    static let deepPurple = Color(red: 0.5, green: 0.0, blue: 1.0)
    static let softPurple = Color(red: 0.5, green: 0.0, blue: 1.0).opacity(0.15)
    
    // Gradiente per le card
    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.1), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

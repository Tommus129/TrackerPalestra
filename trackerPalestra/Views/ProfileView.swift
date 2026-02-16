import SwiftUI
import FirebaseAuth


struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    @State private var showingLogoutAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Info Section
                        VStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryColor.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Theme.primaryColor)
                            }
                            
                            // Email
                            if let email = authService.user?.email {
                                Text(email)
                                    .font(.headline)
                                    .foregroundColor(Theme.textColor)
                            }
                            
                            // User ID (for debug)
                            if let userId = authService.currentUserId {
                                Text("ID: \(userId.prefix(8))...")
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryTextColor)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Account Info Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Informazioni Account")
                                .font(.headline)
                                .foregroundColor(Theme.textColor)
                            
                            Divider()
                                .background(Theme.secondaryTextColor.opacity(0.3))
                            
                            InfoRow(
                                icon: "envelope.fill",
                                title: "Email",
                                value: authService.user?.email ?? "N/A"
                            )
                            
                            InfoRow(
                                icon: "person.fill",
                                title: "Provider",
                                value: authService.user?.providerData.first?.providerID == "google.com" ? "Google" : "Email"
                            )
                            
                            if let creationDate = authService.user?.metadata.creationDate {
                                InfoRow(
                                    icon: "calendar",
                                    title: "Registrato il",
                                    value: formatDate(creationDate)
                                )
                            }
                        }
                        .padding()
                        .background(Theme.cardColor)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Logout Button
                        Button {
                            showingLogoutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Esci")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Conferma Logout", isPresented: $showingLogoutAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Esci", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Sei sicuro di voler uscire?")
            }
            .alert("Errore", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func logout() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = "Errore durante il logout: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primaryColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.secondaryTextColor)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(Theme.textColor)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationService())
}

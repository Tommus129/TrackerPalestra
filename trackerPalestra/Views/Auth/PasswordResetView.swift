import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AuthViewModel
    
    init(authService: AuthenticationService) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.primaryColor)
                        
                        Text("Reset Password")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textColor)
                        
                        Text("Inserisci la tua email per ricevere il link di reset")
                            .font(.subheadline)
                            .foregroundColor(Theme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(Theme.textColor)
                        
                        TextField("email@esempio.it", text: $viewModel.email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error/Success Message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.caption)
                            .foregroundColor(viewModel.errorMessage.contains("inviata") ? .green : .red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Reset Button
                    Button {
                        Task {
                            await viewModel.resetPassword()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Invia Email di Reset")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button("Chiudi") {
                    dismiss()
                }
                .foregroundColor(Theme.primaryColor)
            )
        }
        .preferredColorScheme(.dark)
    }
    
    
}

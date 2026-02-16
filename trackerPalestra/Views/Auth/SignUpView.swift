import SwiftUI

struct SignUpView: View {
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.primaryColor)
                            
                            Text("Crea un account")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textColor)
                            
                            Text("Inizia a tracciare i tuoi allenamenti")
                                .font(.subheadline)
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        .padding(.top, 20)
                        
                        // Sign Up Form
                        VStack(spacing: 16) {
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
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textColor)
                                
                                SecureField("Almeno 6 caratteri", text: $viewModel.password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Conferma Password")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textColor)
                                
                                SecureField("Conferma password", text: $viewModel.confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.newPassword)
                            }
                            
                            // Error Message
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(viewModel.errorMessage.contains("inviata") ? .green : .red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Sign Up Button
                            Button {
                                Task {
                                    await viewModel.signUp()
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Registrati")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(viewModel.isLoading)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Theme.secondaryTextColor.opacity(0.3))
                                    .frame(height: 1)
                                Text("oppure")
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryTextColor)
                                Rectangle()
                                    .fill(Theme.secondaryTextColor.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                            
                            // Google Sign Up Button
                            Button {
                                Task {
                                    await viewModel.signInWithGoogle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Registrati con Google")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Annulla") {
                    dismiss()
                }
                .foregroundColor(Theme.primaryColor)
            )
        }
        .preferredColorScheme(.dark)
    }
}

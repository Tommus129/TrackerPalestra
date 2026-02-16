import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel: AuthViewModel
    @State private var showingSignUp = false
    
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
                        // Logo/Title
                        VStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.primaryColor)
                            
                            Text("TrackerPalestra")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textColor)
                            
                            Text("Accedi al tuo account")
                                .font(.subheadline)
                                .foregroundColor(Theme.secondaryTextColor)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Login Form
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
                                
                                SecureField("Password", text: $viewModel.password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.password)
                            }
                            
                            // Forgot Password
                            Button {
                                viewModel.showingResetPassword = true
                            } label: {
                                Text("Password dimenticata?")
                                    .font(.footnote)
                                    .foregroundColor(Theme.primaryColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            // Error Message
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Login Button
                            Button {
                                Task {
                                    await viewModel.signIn()
                                }
                            } label: {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Accedi")
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
                            
                            // Google Sign In Button
                            Button {
                                Task {
                                    await viewModel.signInWithGoogle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Continua con Google")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(viewModel.isLoading)
                            
                            // Sign Up Link
                            HStack {
                                Text("Non hai un account?")
                                    .foregroundColor(Theme.secondaryTextColor)
                                
                                Button {
                                    viewModel.clearForm()
                                    showingSignUp = true
                                } label: {
                                    Text("Registrati")
                                        .fontWeight(.semibold)
                                        .foregroundColor(Theme.primaryColor)
                                }
                            }
                            .font(.footnote)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(authService: authService)
            }
            .sheet(isPresented: $viewModel.showingResetPassword) {
                PasswordResetView(authService: authService)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Styles

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Theme.cardColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.cardColor)
            .foregroundColor(Theme.textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.secondaryTextColor.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

import Foundation
import SwiftUI
import Combine


@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage = ""
    @Published var isLoading = false
    @Published var showingResetPassword = false
    
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    // MARK: - Validation
    
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    var doPasswordsMatch: Bool {
        return password == confirmPassword
    }
    
    // MARK: - Sign In
    
    func signIn() async {
        guard isEmailValid else {
            errorMessage = "Inserisci un'email valida"
            return
        }
        
        guard isPasswordValid else {
            errorMessage = "La password deve essere di almeno 6 caratteri"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    
    func signUp() async {
        guard isEmailValid else {
            errorMessage = "Inserisci un'email valida"
            return
        }
        
        guard isPasswordValid else {
            errorMessage = "La password deve essere di almeno 6 caratteri"
            return
        }
        
        guard doPasswordsMatch else {
            errorMessage = "Le password non corrispondono"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signUp(email: email, password: password)
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signInWithGoogle()
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    
    func resetPassword() async {
        guard isEmailValid else {
            errorMessage = "Inserisci un'email valida"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "Email di reset inviata. Controlla la tua casella di posta."
        } catch {
            errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007:
            return "Questo account esiste già"
        case 17008:
            return "Email non valida"
        case 17009:
            return "Password errata"
        case 17011:
            return "Nessun account trovato con questa email"
        case 17026:
            return "La password deve essere di almeno 6 caratteri"
        default:
            return error.localizedDescription
        }
    }
    
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = ""
    }
}

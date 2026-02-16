import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import Combine


class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    init() {
        // Ascolta i cambiamenti dello stato di autenticazione
       _ =  Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        self.user = result.user
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.tokenError
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Current User ID
    
    var currentUserId: String? {
        return user?.uid
    }
}

enum AuthError: LocalizedError {
    case missingClientID
    case noRootViewController
    case tokenError
    
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing Firebase Client ID"
        case .noRootViewController:
            return "No root view controller found"
        case .tokenError:
            return "Failed to get ID token"
        }
    }
}

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct trackerPalestraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authService.isAuthenticated, let userId = authService.currentUserId {
                    // ✅ Verifica che userId non sia vuoto
                    HomeView()
                        .environmentObject(MainViewModel(userId: userId))
                        .environmentObject(authService)
                        .onAppear {
                            print("✅ App avviata con userId: \(userId)")
                        }
                } else {
                    LoginView(authService: authService)
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    @available(iOS, deprecated: 26.0, message: "Use UIScene lifecycle instead")
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

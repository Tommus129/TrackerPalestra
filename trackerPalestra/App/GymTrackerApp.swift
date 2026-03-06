import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct trackerPalestraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject private var authService = AuthenticationService()
    @StateObject private var activeWorkoutManager = ActiveWorkoutManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authService.isAuthenticated, let userId = authService.currentUserId {
                    HomeView()
                        .environmentObject(MainViewModel(userId: userId))
                        .environmentObject(authService)
                        .environmentObject(activeWorkoutManager)
                        .onAppear {
                            // Teniamo traccia dello user corrente per i salvataggi di emergenza
                            activeWorkoutManager.currentUserId = userId
                        }
                } else {
                    LoginView(authService: authService)
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            // Continuiamo a provare qui per sicurezza quando va in background normale
            if newPhase == .background {
                activeWorkoutManager.forceSaveDraft()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    // Questo è il metodo più aggressivo e sicuro che iOS ci mette a disposizione
    // Viene chiamato proprio mentre l'app sta per essere killata / sospesa
    func applicationDidEnterBackground(_ application: UIApplication) {
        ActiveWorkoutManager.shared.forceSaveDraft()
    }
    
    // In alcuni casi (es. crash o swipe up brutale) viene chiamato questo
    func applicationWillTerminate(_ application: UIApplication) {
        ActiveWorkoutManager.shared.forceSaveDraft()
    }
    
    @available(iOS, deprecated: 26.0, message: "Use UIScene lifecycle instead")
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

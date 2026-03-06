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
                } else {
                    LoginView(authService: authService)
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Esegue il salvataggio di emergenza a livello globale prima che l'app muoia
                if let session = activeWorkoutManager.activeSession, let userId = authService.currentUserId {
                    let hasInputs = session.exercises.flatMap { $0.sets }.contains { $0.weight > 0 || $0.isCompleted }
                    if hasInputs || !session.notes.isEmpty {
                        // Creiamo un'istanza temporanea del ViewModel solo per salvare nei defaults (metodo sincrono e leggero)
                        let tempViewModel = MainViewModel(userId: userId)
                        tempViewModel.saveDraft(session)
                    }
                }
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
    
    @available(iOS, deprecated: 26.0, message: "Use UIScene lifecycle instead")
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

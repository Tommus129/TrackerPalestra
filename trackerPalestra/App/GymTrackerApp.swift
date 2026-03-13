import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@main
struct trackerPalestraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthenticationService()
    @StateObject private var activeWorkoutManager = ActiveWorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(activeWorkoutManager)
                .preferredColorScheme(.dark)
        }
    }
}

/// View root separata per isolare la creazione del MainViewModel:
/// viene ricreato solo quando cambia davvero lo userId, non ad ogni re-render dell'App.
struct RootView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var activeWorkoutManager: ActiveWorkoutManager

    @State private var trackedUserId: String? = nil
    @State private var viewModel: MainViewModel? = nil

    var body: some View {
        Group {
            if let vm = viewModel, authService.isAuthenticated {
                HomeView()
                    .environmentObject(vm)
                    .environmentObject(authService)
                    .environmentObject(activeWorkoutManager)
            } else {
                LoginView(authService: authService)
                    .environmentObject(authService)
            }
        }
        .onReceive(authService.$user) { user in
            let userId = user?.uid
            guard userId != trackedUserId else { return }
            trackedUserId = userId
            if let userId = userId, !userId.isEmpty {
                viewModel = MainViewModel(userId: userId)
                activeWorkoutManager.currentUserId = userId
            } else {
                viewModel = nil
                activeWorkoutManager.currentUserId = nil
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ActiveWorkoutManager.shared.forceSaveDraft()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ActiveWorkoutManager.shared.forceSaveDraft()
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

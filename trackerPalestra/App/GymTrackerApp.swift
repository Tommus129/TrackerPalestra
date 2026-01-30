import SwiftUI
import FirebaseCore

@main
struct trackerPalestraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject var mainViewModel = MainViewModel(userId: "debug-user")

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(mainViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

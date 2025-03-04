import SwiftUI
import UserNotifications

@main
struct ParentConnectApp: App {
    // Use AppDelegate for handling notifications and remote notifications
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Create shared instances of managers
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Access the persistence controller
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .environmentObject(locationManager)
                .onAppear {
                    // Request permissions when app starts
                    notificationManager.requestAuthorization()
                }
        }
    }
}

import SwiftUI
import UserNotifications

@main
struct ParentConnectApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .environmentObject(locationManager)
        }
    }
}

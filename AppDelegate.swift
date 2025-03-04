import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // In a real app, send this token to your server
        // This is ready for when you implement your backend
        saveDeviceToken(token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This method would send the device token to your backend when you have one
    private func saveDeviceToken(_ token: String) {
        // In the future, this would send the token to your backend
        print("In the future, would send device token to backend: \(token)")
        
        // Store locally for now
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
}

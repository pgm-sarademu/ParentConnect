import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var notificationsAuthorized = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // Check if notifications are authorized
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Request permission for notifications
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                self.notificationsAuthorized = success
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
                
                // Register for remote notifications if authorized
                if success {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    // Schedule a local notification for a playdate
    func schedulePlaydateReminder(playdate: Playdate) {
        // Only proceed if authorized
        guard notificationsAuthorized else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Playdate Reminder"
        content.body = "Your playdate at \(playdate.location) is starting soon"
        content.sound = UNNotificationSound.default
        
        // Create reminder time (30 minutes before playdate)
        let reminderTime = playdate.time.addingTimeInterval(-30 * 60)
        
        // Only schedule if the reminder time is in the future
        guard reminderTime > Date() else { return }
        
        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let identifier = "playdate-\(playdate.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Cancel a playdate reminder
    func cancelPlaydateReminder(playdate: Playdate) {
        let identifier = "playdate-\(playdate.id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // For handling notifications when the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show banner and play sound even when app is open
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // For handling when a user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // Handle notification tap based on identifier
        if identifier.starts(with: "playdate-") {
            // In a real app, navigate to the specific playdate
            // For now, just print the action
            print("User tapped on playdate notification: \(identifier)")
        }
        
        completionHandler()
    }
}

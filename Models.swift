import Foundation

// Shared models across different views
struct EventPreview: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
}

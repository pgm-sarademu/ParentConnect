import SwiftUI
import CoreData

struct EnhancedEventDetailView: View {
    let event: EventPreview
    @State private var isAttending = false
    @State private var showingShareSheet = false
    @State private var showingAttendees = false
    @State private var isPaid = false
    @State private var price: String = ""
    @State private var privacyLevel = "Public"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event image/banner
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    Text("🎪")
                        .font(.system(size: 80))
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Title and info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Privacy badge (based on the stored value)
                            Text(privacyLevel)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(privacyBadgeColor)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatFullDate(event.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatTime(event.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(event.location)
                                .foregroundColor(.secondary)
                        }
                        
                        // Price info (if applicable)
                        if isPaid {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                
                                Text("$\(price)")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                
                                Text("Free")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Event details
                    Text("Event Details")
                        .font(.headline)
                    
                    Text("Join us for a fantastic event suitable for children of all ages. This event promises fun activities, learning opportunities, and a chance to connect with other families in your community.")
                        .foregroundColor(.secondary)
                    
                    // Attendance buttons
                    HStack {
                        Button(action: {
                            isAttending.toggle()
                        }) {
                            HStack {
                                Image(systemName: isAttending ? "checkmark.circle.fill" : "circle")
                                Text(isAttending ? "Attending" : "Attend")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(isAttending ? Color("AppPrimaryColor") : Color(.systemGray6))
                            .foregroundColor(isAttending ? .white : .primary)
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(25)
                        }
                    }
                    
                    // View participants button
                    Button(action: {
                        showingAttendees = true
                    }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("View Participants")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Divider()
                    
                    // Map preview
                    Text("Location")
                        .font(.headline)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .cornerRadius(12)
                        
                        Text("📍 \(event.location)")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    // Organizer info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Organized by")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("👤")
                                        .font(.system(size: 20))
                                )
                            
                            VStack(alignment: .leading) {
                                Text("Community Events Team")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("events@community.org")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadEventDetails)
        .sheet(isPresented: $showingAttendees) {
            NavigationView {
                EventParticipantView(eventId: event.id)
            }
        }
    }
    
    private func loadEventDetails() {
        // In a real app, fetch the event details from Core Data or your API
        // For this example, we'll use mock data based on the privacy settings in UserDefaults
        
        // Get privacy level from UserDefaults
        let privacySettings = UserDefaults.standard.dictionary(forKey: "EventPrivacySettings") as? [String: Int] ?? [:]
        let privacyValue = privacySettings[event.id] ?? 0
        
        switch privacyValue {
        case 1:
            privacyLevel = "Friends Only"
        case 2:
            privacyLevel = "Private"
        default:
            privacyLevel = "Public"
        }
        
        // In a real app, you would get this from the Event entity
        isPaid = false
        price = "0.00"
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var privacyBadgeColor: Color {
        switch privacyLevel {
        case "Public":
            return Color.green
        case "Friends Only":
            return Color.orange
        case "Private":
            return Color.red
        default:
            return Color.gray
        }
    }
}

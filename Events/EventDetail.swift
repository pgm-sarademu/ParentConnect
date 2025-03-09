import SwiftUI
import CoreData

struct EventDetail: View {
    let event: EventPreview
    @State private var isAttending = false
    @State private var showingShareSheet = false
    @State private var showingAttendees = false
    @State private var isPaid = false
    @State private var price: String = ""
    @State private var privacyLevel = "Public"
    
    // Participant limit states
    @State private var hasParticipantLimit = false
    @State private var maxChildCount = 0
    @State private var spotsRemaining = 0
    @State private var limitDescription = ""
    @State private var participantCount = 0
    @State private var childrenCount = 0
    
    // Group chat state variables
    @State private var showingGroupChat = false
    @State private var unreadMessages = 2 // In a real app, this would be fetched from data model
    
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
                        
                        // Capacity info (if applicable)
                        if hasParticipantLimit {
                            HStack {
                                Image(systemName: "person.3")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                
                                Group {
                                    if spotsRemaining > 0 {
                                        Text("\(spotsRemaining) spots remaining")
                                            .foregroundColor(spotsRemaining <= 5 ? .orange : .secondary)
                                    } else {
                                        Text("Event full")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            if !limitDescription.isEmpty {
                                Text(limitDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Event details
                    Text("Event Details")
                        .font(.headline)
                    
                    Text("Join us for a fantastic event suitable for children of all ages. This event promises fun activities, learning opportunities, and a chance to connect with other families in your community.")
                        .foregroundColor(.secondary)
                    
                    // Attendance info
                    if participantCount > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Currently attending:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("\(participantCount) parents with \(childrenCount) children")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Attendance buttons
                    HStack {
                        Button(action: {
                            // Check if event is full before allowing attendance
                            if hasParticipantLimit && spotsRemaining <= 0 && !isAttending {
                                // Show alert that event is full
                                return
                            }
                            
                            isAttending.toggle()
                        }) {
                            HStack {
                                Image(systemName: isAttending ? "checkmark.circle.fill" : "circle")
                                Text(isAttending ? "Attending" : "Attend")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                (hasParticipantLimit && spotsRemaining <= 0 && !isAttending)
                                ? Color(.systemGray4)
                                : (isAttending ? Color("AppPrimaryColor") : Color(.systemGray6))
                            )
                            .foregroundColor(
                                (hasParticipantLimit && spotsRemaining <= 0 && !isAttending)
                                ? Color(.systemGray2)
                                : (isAttending ? .white : .primary)
                            )
                            .cornerRadius(25)
                        }
                        .disabled(hasParticipantLimit && spotsRemaining <= 0 && !isAttending)
                        
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
                    
                    // Group chat button
                    Button(action: {
                        showingGroupChat = true
                    }) {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Event Chat")
                            Spacer()
                            if unreadMessages > 0 {
                                Text("\(unreadMessages) new")
                                    .font(.caption)
                                    .foregroundColor(Color("AppPrimaryColor"))
                            }
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
        // Sheet for group chat
        .sheet(isPresented: $showingGroupChat) {
            NavigationView {
                GroupChat(eventId: event.id, eventTitle: event.title)
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
        
        // Load limit information
        // In a real app, this would be fetched from Core Data
        
        // Simulating an event with participant limit for demo
        // Randomly determine if event has a limit
        let idValue = Int(event.id) ?? 0
        hasParticipantLimit = idValue % 3 == 0 // Every third event has a limit
        
        if hasParticipantLimit {
            maxChildCount = 15 // Demo value
            
            // Demo attendance count
            participantCount = Int.random(in: 3...10)
            childrenCount = Int.random(in: participantCount...(participantCount + 5))
            
            // Calculate spots remaining based on children count
            spotsRemaining = max(0, maxChildCount - childrenCount)
            
            // Get limit description if available
            let limitDescriptions = UserDefaults.standard.dictionary(forKey: "EventLimitDescriptions") as? [String: String] ?? [:]
            limitDescription = limitDescriptions[event.id] ?? "Limited to \(maxChildCount) children total."
        } else {
            // For events without limits, just show some random attendance
            participantCount = Int.random(in: 2...8)
            childrenCount = Int.random(in: participantCount...(participantCount + 8))
        }
        
        // In a real app, you would get this from the Event entity
        isPaid = false
        price = "0.00"
        
        // Load unread message count for group chat
        // In a real app, this would be fetched from your data store
        unreadMessages = Int.random(in: 0...5)
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

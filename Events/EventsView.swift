import SwiftUI
import CoreData
import MapKit

struct EventsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var events: [EventPreview] = []
    @State private var searchText = ""
    @State private var selectedFilter: String? = "All"
    @State private var showingCreateEventSheet = false
    @State private var showingEventDetails = false
    @State private var selectedEvent: EventPreview?
    
    let filters = ["All", "Today", "This Week", "Kid-Friendly", "Free", "My Events"]
    
    var filteredEvents: [EventPreview] {
        var filtered = events
        
        // Filter by selected filter
        if let filter = selectedFilter, filter != "All" {
            switch filter {
            case "Today":
                let today = Calendar.current.startOfDay(for: Date())
                filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            case "This Week":
                let today = Calendar.current.startOfDay(for: Date())
                guard let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: today) else {
                    return filtered
                }
                filtered = filtered.filter { $0.date >= today && $0.date <= oneWeekLater }
            case "Kid-Friendly":
                // Filter for age-appropriate events
                // In a real app, you would check the ageRange property
                break
            case "Free":
                // Filter for free events
                filtered = filtered.filter { !$0.isPaid }
            case "My Events":
                // Show only events created by current user
                filtered = filtered.filter { $0.createdBy == "currentUserId" }
            default:
                break
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by visibility settings
        filtered = filtered.filter { event in
            // Creator can always see their own events
            if event.createdBy == "currentUserId" {
                return true
            }
            
            // Apply visibility filters
            switch event.visibilityLevel {
            case "Public":
                return true
            case "Friends Only":
                // In a real app, this would check if the creator is a friend
                return true // For demo purposes, we show all "Friends Only" events
            case "Invite Only":
                // In a real app, this would check if the user was invited
                return event.invitedIds.contains("currentUserId")
            case "Private":
                return false
            default:
                return true
            }
        }
        
        return filtered.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ?
                                        Color("AppPrimaryColor") :
                                        Color(.systemGray6)
                                    )
                                    .foregroundColor(
                                        selectedFilter == filter ?
                                        .white :
                                        .primary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))
                
                // Divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                
                if filteredEvents.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No events found")
                            .font(.headline)
                        
                        Text("Try changing your filters or check back later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            selectedFilter = "All"
                            searchText = ""
                        }) {
                            Text("Clear filters")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("AppPrimaryColor"))
                                .cornerRadius(20)
                        }
                        .padding(.top, 10)
                        
                        // Add Create Event button in empty state
                        Button(action: {
                            showingCreateEventSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create New Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(20)
                        }
                        .padding(.top, 5)
                        
                        Spacer()
                    }
                } else {
                    // Events list
                    List {
                        ForEach(filteredEvents) { event in
                            EventListRow(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedEvent = event
                                    showingEventDetails = true
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Events")
            .searchable(text: $searchText, prompt: "Search events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                }
            }
            .sheet(isPresented: $showingCreateEventSheet) {
                CreateEventView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(locationManager)
            }
            .sheet(isPresented: $showingEventDetails) {
                if let event = selectedEvent {
                    NavigationView {
                        EventDetailView(event: event)
                    }
                }
            }
            .onAppear {
                loadEvents()
            }
        }
    }
    
    private func loadEvents() {
        // In a real app, this would fetch events from Core Data
        loadMockEvents()
    }
    
    private func loadMockEvents() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        events = [
            EventPreview(
                id: "1",
                title: "Storytime at Library",
                date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
                location: "Central Library",
                description: "Join us for an interactive storytime session designed for children ages 3-5. We'll read exciting stories, sing songs, and do simple crafts.",
                createdBy: "user2",
                visibilityLevel: "Public",
                isPaid: false,
                price: 0.0,
                capacity: 20,
                spotsRemaining: 12,
                ageRange: "3-5 years",
                invitedIds: [],
                participantIds: []
            ),
            EventPreview(
                id: "2",
                title: "Park Playdate",
                date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate,
                location: "Sunshine Park",
                description: "Casual meetup at the playground. Bring your kids for some outdoor fun!",
                createdBy: "currentUserId",
                visibilityLevel: "Friends Only",
                isPaid: false,
                price: 0.0,
                capacity: 10,
                spotsRemaining: 5,
                ageRange: "All Ages",
                invitedIds: [],
                participantIds: ["user3", "user4"]
            ),
            EventPreview(
                id: "3",
                title: "Kids Art Class",
                date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                location: "Community Center",
                description: "Guided art session where children can explore various materials and techniques. All supplies provided.",
                createdBy: "user3",
                visibilityLevel: "Public",
                isPaid: true,
                price: 15.0,
                capacity: 15,
                spotsRemaining: 8,
                ageRange: "6-8 years",
                invitedIds: [],
                participantIds: []
            ),
            EventPreview(
                id: "4",
                title: "Family Movie Night",
                date: calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate,
                location: "City Theater",
                description: "Special screening of family-friendly movies. Popcorn and drinks available for purchase.",
                createdBy: "user4",
                visibilityLevel: "Public",
                isPaid: true,
                price: 8.0,
                capacity: 50,
                spotsRemaining: 20,
                ageRange: "All Ages",
                invitedIds: [],
                participantIds: []
            ),
            EventPreview(
                id: "5",
                title: "Swimming Lessons",
                date: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                location: "Community Pool",
                description: "Beginner swimming lessons for children. Taught by certified instructors in a safe environment.",
                createdBy: "currentUserId",
                visibilityLevel: "Invite Only",
                isPaid: true,
                price: 25.0,
                capacity: 8,
                spotsRemaining: 3,
                ageRange: "3-5 years",
                invitedIds: ["user2", "user6"],
                participantIds: ["user2"]
            ),
            EventPreview(
                id: "6",
                title: "Parent Support Group",
                date: calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate,
                location: "Family Center",
                description: "A safe space for parents to share experiences, challenges, and advice. Childcare provided during the meeting.",
                createdBy: "user5",
                visibilityLevel: "Public",
                isPaid: false,
                price: 0.0,
                capacity: 15,
                spotsRemaining: 10,
                ageRange: "Parents Only",
                invitedIds: [],
                participantIds: []
            ),
            EventPreview(
                id: "7",
                title: "Private Playdate",
                date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate,
                location: "Home",
                description: "Personal playdate at my house.",
                createdBy: "currentUserId",
                visibilityLevel: "Private",
                isPaid: false,
                price: 0.0,
                capacity: 4,
                spotsRemaining: 2,
                ageRange: "2-4 years",
                invitedIds: [],
                participantIds: []
            )
        ]
    }
}

// Enhanced EventPreview model with all needed properties
struct EventPreview: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
    let description: String
    let createdBy: String
    let visibilityLevel: String
    let isPaid: Bool
    let price: Double
    let capacity: Int
    let spotsRemaining: Int
    let ageRange: String
    let invitedIds: [String]
    let participantIds: [String]
    
    // Constructor for backward compatibility
    init(id: String, title: String, date: Date, location: String) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.description = ""
        self.createdBy = ""
        self.visibilityLevel = "Public"
        self.isPaid = false
        self.price = 0.0
        self.capacity = 0
        self.spotsRemaining = 0
        self.ageRange = "All Ages"
        self.invitedIds = []
        self.participantIds = []
    }
    
    // Full constructor
    init(id: String, title: String, date: Date, location: String, description: String, createdBy: String,
         visibilityLevel: String, isPaid: Bool, price: Double, capacity: Int, spotsRemaining: Int,
         ageRange: String, invitedIds: [String], participantIds: [String]) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.description = description
        self.createdBy = createdBy
        self.visibilityLevel = visibilityLevel
        self.isPaid = isPaid
        self.price = price
        self.capacity = capacity
        self.spotsRemaining = spotsRemaining
        self.ageRange = ageRange
        self.invitedIds = invitedIds
        self.participantIds = participantIds
    }
}

// Enhanced event list row with more details
struct EventListRow: View {
    let event: EventPreview
    
    var body: some View {
        HStack(spacing: 15) {
            // Date component
            VStack(spacing: 2) {
                Text(formatDay(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDayNumber(event.date))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimaryColor"))
                
                Text(formatMonth(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color("AppPrimaryColor").opacity(0.1))
            .cornerRadius(8)
            
            // Event info
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if event.createdBy == "currentUserId" {
                        Text("Your Event")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("AppPrimaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(event.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    // Price indicator
                    if event.isPaid {
                        Text("$\(String(format: "%.2f", event.price))")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    } else {
                        Text("Free")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    // Visibility indicator
                    Text(event.visibilityLevel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(visibilityColor(event.visibilityLevel).opacity(0.2))
                        .foregroundColor(visibilityColor(event.visibilityLevel))
                        .cornerRadius(4)
                    
                    // Age range
                    Text(event.ageRange)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func visibilityColor(_ level: String) -> Color {
        switch level {
        case "Public":
            return .purple
        case "Friends Only":
            return .orange
        case "Invite Only":
            return .blue
        case "Private":
            return .gray
        default:
            return .purple
        }
    }
}

// Event detail view with full information
struct EventDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    let event: EventPreview
    @State private var isAttending = false
    @State private var showingShareSheet = false
    @State private var showingInviteSheet = false
    @State private var showingParticipantsView = false
    
    var isUserCreator: Bool {
        return event.createdBy == "currentUserId"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event image/banner
                ZStack(alignment: .bottomTrailing) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text("🎪")
                                .font(.system(size: 80))
                        )
                    
                    HStack {
                        // Age range tag
                        Text(event.ageRange)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        // Price tag
                        if event.isPaid {
                            Text("$\(String(format: "%.2f", event.price))")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        } else {
                            Text("Free")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(8)
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 15) {
                    // Title and creator info
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Show badge if current user created this event
                            if isUserCreator {
                                Text("Your Event")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color("AppPrimaryColor"))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Date and time
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
                        
                        // Location
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(event.location)
                                .foregroundColor(.secondary)
                        }
                        
                        // Visibility info
                        HStack {
                            Image(systemName: visibilityIcon(for: event.visibilityLevel))
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Visibility: \(event.visibilityLevel)")
                                .foregroundColor(.secondary)
                        }
                        
                        // Capacity info
                        HStack {
                            Image(systemName: "person.3")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("\(event.capacity - event.spotsRemaining)/\(event.capacity) participants")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                showingParticipantsView = true
                            }) {
                                Text("View")
                                    .font(.caption)
                                    .foregroundColor(Color("AppPrimaryColor"))
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Event description
                    Text("Event Details")
                        .font(.headline)
                    
                    Text(event.description)
                        .foregroundColor(.secondary)
                    
                    // Attendance and sharing buttons
                    HStack {
                        // Attend button
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
                        
                        // Invite button (only shown for event creator or if invite-only event)
                        if isUserCreator || event.visibilityLevel == "Invite Only" {
                            Button(action: {
                                showingInviteSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                    Text("Invite")
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(25)
                            }
                        }
                        
                        // Share button
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
                                Text(isUserCreator ? "You" : "Community Events Team")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(isUserCreator ? "Event Creator" : "events@community.org")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Edit/Delete buttons (only shown for event creator)
                        if isUserCreator {
                            HStack {
                                Button(action: {
                                    // Edit event action
                                }) {
                                    HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit")
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color("AppPrimaryColor").opacity(0.2))
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .cornerRadius(20)
                                }
                                
                                Button(action: {
                                    // Delete event action
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.red.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.top, 10)
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitle("Event Details", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Close")
                .foregroundColor(Color("AppPrimaryColor"))
        })
        .sheet(isPresented: $showingInviteSheet) {
            NavigationView {
                EventInviteView(eventId: event.id)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingParticipantsView) {
            NavigationView {
                EventParticipantsView(eventId: event.id, isCreator: isUserCreator)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
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
    
    private func visibilityIcon(for level: String) -> String {
        switch level {
        case "Public":
            return "globe"
        case "Friends Only":
            return "person.2"
        case "Invite Only":
            return "envelope"
        case "Private":
            return "lock"
        default:
            return "globe"
        }
    }
}

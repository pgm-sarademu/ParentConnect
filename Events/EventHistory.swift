import SwiftUI
import CoreData

// Shows the user's event attendance history
struct EventHistory: View {
    @State private var pastEvents: [EventHistoryItem] = []
    @State private var isLoading = true
    @State private var showingEventDetails = false
    @State private var selectedEvent: EventHistoryItem?
    @State private var showingFilterOptions = false
    @State private var filterTimeFrame: TimeFrame = .allTime
    @State private var searchText = ""

    
    enum TimeFrame: String, CaseIterable {
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case lastYear = "Last Year"
        case allTime = "All Time"
    }
    
    var filteredEvents: [EventHistoryItem] {
        if searchText.isEmpty {
            return pastEvents
        } else {
            return pastEvents.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title without profile button
            HStack {
                Text("Event History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 15)
            
            // Filter & search header
            HStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search event history", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filter button
                Button(action: {
                    showingFilterOptions = true
                }) {
                    HStack {
                        Text(filterTimeFrame.rawValue)
                            .font(.subheadline)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(Color("AppPrimaryColor"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("AppPrimaryColor").opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            if isLoading {
                Spacer()
                ProgressView("Loading your event history...")
                Spacer()
            } else if filteredEvents.isEmpty {
                Spacer()
                VStack(spacing: 15) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(Color(.systemGray3))
                    
                    Text("No past events found")
                        .font(.headline)
                    
                    Text("When you attend events, they'll appear here so you can connect with other parents you've met.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    NavigationLink(destination: EventsView()) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Browse Upcoming Events")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(20)
                    }
                    .padding(.top, 10)
                }
                Spacer()
            } else {
                // Grid layout for past events
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 16)], spacing: 16) {
                        ForEach(filteredEvents) { event in
                            Button(action: {
                                selectedEvent = event
                                showingEventDetails = true
                            }) {
                                EventHistoryCard(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .onAppear {
            loadPastEvents()
        }
        .sheet(isPresented: $showingEventDetails) {
            if let event = selectedEvent {
                PastEventDetail(event: event)
            }
        }

        .actionSheet(isPresented: $showingFilterOptions) {
            ActionSheet(
                title: Text("Filter by time"),
                buttons: TimeFrame.allCases.map { timeFrame in
                    .default(Text(timeFrame.rawValue)) {
                        filterTimeFrame = timeFrame
                        loadPastEvents() // Reload with new filter
                    }
                } + [.cancel()]
            )
        }
    }
    
    private func loadPastEvents() {
        isLoading = true
        
        // Simulate API/database fetch delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, we would fetch from Core Data or server
            // and apply the timeFrame filter to the query
            
            // For now, we'll use mock data
            pastEvents = [
                EventHistoryItem(
                    id: "1",
                    title: "Park Playdate",
                    date: Date().addingTimeInterval(-7*24*3600), // 1 week ago
                    location: "Sunshine Park",
                    totalAttendees: 8,
                    connectionsMade: 2,
                    imageEmoji: "🏞️"
                ),
                EventHistoryItem(
                    id: "2",
                    title: "Storytelling at Library",
                    date: Date().addingTimeInterval(-14*24*3600), // 2 weeks ago
                    location: "Central Library",
                    totalAttendees: 15,
                    connectionsMade: 1,
                    imageEmoji: "📚"
                ),
                EventHistoryItem(
                    id: "3",
                    title: "Science Workshop for Kids",
                    date: Date().addingTimeInterval(-30*24*3600), // 1 month ago
                    location: "Science Museum",
                    totalAttendees: 22,
                    connectionsMade: 3,
                    imageEmoji: "🔬"
                ),
                EventHistoryItem(
                    id: "4",
                    title: "Swimming Lessons",
                    date: Date().addingTimeInterval(-45*24*3600), // 1.5 months ago
                    location: "Community Pool",
                    totalAttendees: 12,
                    connectionsMade: 0,
                    imageEmoji: "🏊‍♂️"
                ),
                EventHistoryItem(
                    id: "5",
                    title: "Family Movie Night",
                    date: Date().addingTimeInterval(-60*24*3600), // 2 months ago
                    location: "City Theater",
                    totalAttendees: 30,
                    connectionsMade: 4,
                    imageEmoji: "🎬"
                )
            ]
            
            // Filter based on the selected time frame
            let currentDate = Date()
            var cutoffDate: Date?
            
            switch filterTimeFrame {
            case .lastMonth:
                cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate)
            case .last3Months:
                cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: currentDate)
            case .last6Months:
                cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: currentDate)
            case .lastYear:
                cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)
            case .allTime:
                cutoffDate = nil
            }
            
            if let cutoffDate = cutoffDate {
                pastEvents = pastEvents.filter { $0.date >= cutoffDate }
            }
            
            isLoading = false
        }
    }
}

struct EventHistoryItem: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
    let totalAttendees: Int
    let connectionsMade: Int
    let imageEmoji: String
}

// Grid card view for event history
struct EventHistoryCard: View {
    let event: EventHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event image with date overlay
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay(
                        Text(event.imageEmoji)
                            .font(.system(size: 40))
                    )
                
                // Date badge overlay
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text(formatDay(event.date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(formatDayNumber(event.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            
                        Text(formatMonth(event.date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AppPrimaryColor"))
                    .cornerRadius(8)
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(event.location)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Attendee info
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text("\(event.totalAttendees) attendees")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Connection info if any
                if event.connectionsMade > 0 {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("\(event.connectionsMade) connections")
                            .font(.system(size: 12))
                            .foregroundColor(Color("AppPrimaryColor"))
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

struct PastEventDetail: View {
    let event: EventHistoryItem
    @State private var attendees: [AttendeeInfo] = []
    @State private var isLoading = true
    @State private var showUserCard = false
    @State private var userCardOffset: CGFloat = 400
    @State private var selectedParticipant: ParticipantInfo?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event header
                    ZStack(alignment: .bottom) {
                        // Event banner
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 180)
                            .overlay(
                                Text(event.imageEmoji)
                                    .font(.system(size: 70))
                            )
                        
                        // Date badge
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(formattedDate(event.date))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Past Event")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(8)
                        }
                        .padding([.bottom, .leading], 16)
                    }
                    
                    // Event details
                    VStack(alignment: .leading, spacing: 15) {
                        Text(event.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text(event.location)
                                .foregroundColor(.secondary)
                        }
                        
                        // Attendance info
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(event.totalAttendees) parents attended")
                                .font(.headline)
                            
                            if event.connectionsMade > 0 {
                                Text("You made \(event.connectionsMade) connections at this event")
                                    .foregroundColor(Color("AppPrimaryColor"))
                            } else {
                                Text("You haven't connected with any parents from this event yet")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color("AppPrimaryColor").opacity(0.1))
                        .cornerRadius(8)
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        // Attendees section
                        Text("Parents You Met")
                            .font(.headline)
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if attendees.isEmpty {
                            HStack {
                                Spacer()
                                Text("No attendee information available")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(attendees) { attendee in
                                    Button(action: {
                                        displayUserCardFor(attendee)
                                    }) {
                                        HStack {
                                            // Avatar placeholder
                                            ZStack {
                                                Circle()
                                                    .fill(Color("AppPrimaryColor").opacity(0.2))
                                                    .frame(width: 50, height: 50)
                                                
                                                Text("👤")
                                                    .font(.title)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(attendee.name)
                                                    .font(.headline)
                                                
                                                HStack {
                                                    Text(attendee.childrenInfo)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    // Child count badge
                                                    Text("\(attendee.childCount)")
                                                        .font(.caption)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color("AppPrimaryColor"))
                                                        .foregroundColor(.white)
                                                        .clipShape(Circle())
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if attendee.isConnected {
                                                Text("Connected")
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(10)
                                            } else {
                                                Text("Connect")
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(Color("AppPrimaryColor"))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if attendee.id != attendees.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            
            // Overlay for user card
            if showUserCard && selectedParticipant != nil {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideUserCard()
                    }
                
                UserCard(
                    user: selectedParticipant!,
                    isPresented: $showUserCard,
                    onConnectTapped: { isConnected in
                        // Handle connection change
                        handleConnectionChange(isConnected: isConnected)
                    }
                )
                .offset(y: userCardOffset)
                .animation(.spring(dampingFraction: 0.7), value: userCardOffset)
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(Color("AppPrimaryColor"))
            Text("Back")
                .foregroundColor(Color("AppPrimaryColor"))
        })
        .onAppear {
            loadAttendees()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func loadAttendees() {
        // In a real app, load from data store
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, fetch this data from Core Data or your backend API
            self.attendees = [
                AttendeeInfo(id: "1", name: "Sarah Johnson", childrenInfo: "2 kids (4, 6)", childCount: 2, isConnected: self.event.connectionsMade > 0),
                AttendeeInfo(id: "2", name: "Mike Thompson", childrenInfo: "1 kid (3)", childCount: 1, isConnected: self.event.connectionsMade > 1),
                AttendeeInfo(id: "3", name: "Emma Roberts", childrenInfo: "3 kids (2, 5, 7)", childCount: 3, isConnected: self.event.connectionsMade > 2),
                AttendeeInfo(id: "4", name: "David Wilson", childrenInfo: "2 kids (4, 8)", childCount: 2, isConnected: self.event.connectionsMade > 3)
            ]
            
            self.isLoading = false
        }
    }
    
    private func displayUserCardFor(_ attendee: AttendeeInfo) {
        // Create a participant info object from the attendee
        // Get child count from the attendee
        let childCount = attendee.childCount
        
        // Create mock children based on available info
        var children: [ChildInfo] = []
        for i in 0..<childCount {
            // Parse ages from childrenInfo if possible, otherwise use placeholder ages
            let age = i < childCount ? (4 + i) : 5
            let name = ["Emma", "Noah", "Olivia", "Liam", "Ava"][i % 5]
            children.append(ChildInfo(id: UUID().uuidString, name: name, age: age))
        }
        
        // Create the participant info
        selectedParticipant = ParticipantInfo(
            id: attendee.id,
            name: attendee.name,
            location: "New York City",
            bio: "Parent interested in community activities and playdates.",
            children: children
        )
        
        // Show the user card with animation
        withAnimation {
            showUserCard = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    userCardOffset = 0
                }
            }
        }
    }
    
    private func hideUserCard() {
        withAnimation {
            userCardOffset = 400
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showUserCard = false
                selectedParticipant = nil
            }
        }
    }
    
    private func handleConnectionChange(isConnected: Bool) {
        guard let participant = selectedParticipant,
              let index = attendees.firstIndex(where: { $0.id == participant.id }) else {
            return
        }
        
        // Update the local model to reflect connection status change
        attendees[index].isConnected = isConnected
    }
}

struct AttendeeInfo: Identifiable {
    let id: String
    let name: String
    let childrenInfo: String
    let childCount: Int
    var isConnected: Bool
}

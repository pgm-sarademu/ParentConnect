import SwiftUI
import CoreData
import MapKit

// Enhanced Event model with new fields
struct EventItem: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
    let description: String
    let ageRange: String
    let createdBy: String
    let coordinate: CLLocationCoordinate2D
    let isPaid: Bool
    let price: Double?  // Optional price (nil for free events)
    let capacity: Int?  // Optional capacity (nil for unlimited)
    let spotsRemaining: Int?  // Optional spots remaining
    let distance: Double?  // Distance from user's location in miles
}

struct EventsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Event.date, ascending: true)],
        animation: .default)
    private var cdEvents: FetchedResults<Event>
    
    @State private var searchText = ""
    @State private var selectedTimeFrame: TimeFrame = .upcoming
    @State private var showingAddEventSheet = false
    @State private var showingMapView = false
    @State private var selectedPriceFilter: PriceFilter = .all
    @State private var userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to San Francisco
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Enum to define time frame options for filtering
    enum TimeFrame: String, CaseIterable {
        case upcoming = "Upcoming"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    // Enum to define price filter options
    enum PriceFilter: String, CaseIterable {
        case all = "All"
        case free = "Free"
        case paid = "Paid"
    }
    
    // Computed property to filter events based on search, time frame, and price
    var filteredEvents: [EventItem] {
        // Create mock events array for now
        let eventsArray = mockEvents()
        
        // Filter using array methods
        return eventsArray.filter { event in
            // Filter by search text
            let matchesSearch = searchText.isEmpty ||
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText)
            
            // Filter by time frame
            let calendar = Calendar.current
            let now = Date()
            let matchesTimeFrame: Bool
            
            switch selectedTimeFrame {
            case .today:
                matchesTimeFrame = calendar.isDateInToday(event.date)
            case .thisWeek:
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: now)!
                matchesTimeFrame = event.date >= now && event.date <= endOfWeek
            case .thisMonth:
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: now)!
                matchesTimeFrame = event.date >= now && event.date <= endOfMonth
            case .upcoming:
                matchesTimeFrame = event.date >= now
            }
            
            // Filter by price
            let matchesPrice: Bool
            switch selectedPriceFilter {
            case .all:
                matchesPrice = true
            case .free:
                matchesPrice = !event.isPaid
            case .paid:
                matchesPrice = event.isPaid
            }
            
            return matchesSearch && matchesTimeFrame && matchesPrice
        }.sorted {
            // Sort by proximity first, then by date
            if let distance1 = $0.distance, let distance2 = $1.distance {
                if abs(distance1 - distance2) > 1.0 { // If distances differ by more than 1 mile
                    return distance1 < distance2
                }
            }
            return $0.date < $1.date
        }
    }
    
    // Suggested events (nearby events happening soon)
    var suggestedEvents: [EventItem] {
        return filteredEvents
            .filter { $0.date > Date() && $0.date < Date().addingTimeInterval(86400 * 7) } // Events in the next week
            .sorted {
                // Prioritize nearby events
                if let distance1 = $0.distance, let distance2 = $1.distance {
                    return distance1 < distance2
                }
                return $0.date < $1.date
            }
            .prefix(3) // Top 3 suggestions
            .map { $0 }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Map preview with toggle button
                ZStack(alignment: .topTrailing) {
                    // Map with event markers
                    Map(coordinateRegion: $region, annotationItems: filteredEvents) { event in
                        MapAnnotation(coordinate: event.coordinate) {
                            VStack {
                                Image(systemName: event.isPaid ? "dollarsign.circle.fill" : "calendar.circle.fill")
                                    .foregroundColor(event.isPaid ? .green : Color("AppPrimaryColor"))
                                    .font(.title)
                                    .shadow(radius: 2)
                                
                                Text(event.title)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                                    .shadow(radius: 1)
                            }
                            .onTapGesture {
                                // Navigate to event details (would need to be implemented with navigation state)
                            }
                        }
                    }
                    .frame(height: showingMapView ? 300 : 150)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Expand/collapse button
                    Button(action: {
                        withAnimation {
                            showingMapView.toggle()
                        }
                    }) {
                        Image(systemName: showingMapView ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title)
                            .foregroundColor(Color("AppPrimaryColor"))
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                
                // Price filter
                Picker("Price", selection: $selectedPriceFilter) {
                    ForEach(PriceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Time frame filter
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Suggestions section
                if !suggestedEvents.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Suggestions Nearby")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(suggestedEvents) { event in
                                    SuggestedEventCard(event: event)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if filteredEvents.isEmpty {
                    // Empty state when no events match the criteria
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No events found")
                            .font(.headline)
                        
                        Text("Try changing your search or time frame")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingAddEventSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Your Own Event")
                            }
                            .padding()
                            .background(Color("AppPrimaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    // List of events
                    List {
                        ForEach(filteredEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventListItem(event: event)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Events")
            .navigationBarItems(trailing:
                Button(action: {
                    showingAddEventSheet = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            )
            .searchable(text: $searchText, prompt: "Search events")
            .sheet(isPresented: $showingAddEventSheet) {
                // Create event view with new fields would go here
            }
            .onAppear {
                // Update region to focus on user's location
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
    
    // Mock events with new fields for testing
    private func mockEvents() -> [EventItem] {
        return [
            EventItem(
                id: "1",
                title: "Storytime at Library",
                date: Date().addingTimeInterval(86400), // Tomorrow
                location: "Central Library",
                description: "Join us for a special storytime session with children's author Jane Smith.",
                ageRange: "3-5 years",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                isPaid: false,
                price: nil,
                capacity: 30,
                spotsRemaining: 12,
                distance: 0.8
            ),
            EventItem(
                id: "2",
                title: "Park Playdate",
                date: Date().addingTimeInterval(172800), // Day after tomorrow
                location: "Sunshine Park",
                description: "Informal playdate at the new playground. All ages welcome!",
                ageRange: "All ages",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7739, longitude: -122.4312),
                isPaid: false,
                price: nil,
                capacity: nil,
                spotsRemaining: nil,
                distance: 1.2
            ),
            EventItem(
                id: "3",
                title: "Kids Art Class",
                date: Date().addingTimeInterval(259200), // 3 days from now
                location: "Community Center",
                description: "Introductory art class for children ages 3-6. All materials provided.",
                ageRange: "3-6 years",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7699, longitude: -122.4111),
                isPaid: true,
                price: 15.00,
                capacity: 15,
                spotsRemaining: 5,
                distance: 1.5
            ),
            EventItem(
                id: "4",
                title: "Family Movie Night",
                date: Date().addingTimeInterval(432000), // 5 days from now
                location: "Memorial Park",
                description: "Outdoor movie screening of 'The Secret Garden'. Bring blankets and snacks!",
                ageRange: "All ages",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7829, longitude: -122.4024),
                isPaid: true,
                price: 8.50,
                capacity: 100,
                spotsRemaining: 67,
                distance: 2.3
            ),
            EventItem(
                id: "5",
                title: "Science Workshop",
                date: Date().addingTimeInterval(518400), // 6 days from now
                location: "Children's Museum",
                description: "Hands-on science experiments for kids ages 5-10.",
                ageRange: "5-10 years",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7569, longitude: -122.4148),
                isPaid: true,
                price: 25.00,
                capacity: 20,
                spotsRemaining: 3,
                distance: 3.1
            ),
            EventItem(
                id: "6",
                title: "Baby & Me Yoga",
                date: Date(), // Today
                location: "Wellness Center",
                description: "Gentle yoga for parents with babies aged 2-12 months.",
                ageRange: "0-1 year",
                createdBy: "System",
                coordinate: CLLocationCoordinate2D(latitude: 37.7869, longitude: -122.4000),
                isPaid: true,
                price: 12.00,
                capacity: 12,
                spotsRemaining: 4,
                distance: 1.8
            )
        ]
    }
}

// Component to display an event in the list
struct EventListItem: View {
    let event: EventItem
    
    var body: some View {
        HStack(spacing: 15) {
            // Event icon based on age range
            ZStack {
                Circle()
                    .fill(Color("AppPrimaryColor").opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(ageRangeEmoji(for: event.ageRange))
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Price tag
                    if event.isPaid {
                        Text("$\(event.price?.formatted() ?? "Paid")")
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
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Date and time with calendar icon
                    Image(systemName: "calendar")
                        .foregroundColor(Color("AppPrimaryColor"))
                    Text(formatDate(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Age range with person icon
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color("AppPrimaryColor"))
                    Text(event.ageRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Capacity indicator (if applicable)
                    if let capacity = event.capacity, let remaining = event.spotsRemaining {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                        Text("\(remaining)/\(capacity) spots")
                            .font(.caption)
                            .foregroundColor(remaining < 5 ? .orange : .secondary)
                    }
                }
                
                // Distance indicator
                if let distance = event.distance {
                    Text("\(String(format: "%.1f", distance)) miles away")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Helper function to format date in a readable format
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to get an appropriate emoji based on age range
    private func ageRangeEmoji(for ageRange: String) -> String {
        if ageRange.contains("0-1") {
            return "👶"
        } else if ageRange.contains("All ages") {
            return "👨‍👩‍👧‍👦"
        } else if ageRange.lowercased().contains("year") && Int(ageRange.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0 < 5 {
            return "🧒"
        } else {
            return "👧"
        }
    }
}

// Component for suggested events
struct SuggestedEventCard: View {
    let event: EventItem
    
    var body: some View {
        VStack(alignment: .leading) {
            // Event image/icon
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 100)
                    .overlay(
                        Text(ageRangeEmoji(for: event.ageRange))
                            .font(.system(size: 40))
                    )
                
                // Price tag
                if event.isPaid {
                    Text("$\(event.price?.formatted() ?? "")")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                } else {
                    Text("Free")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    // Time info
                    Text(formatDate(event.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Distance
                    if let distance = event.distance {
                        Text("\(String(format: "%.1f", distance))mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Capacity
                if let remaining = event.spotsRemaining, let capacity = event.capacity {
                    if remaining < 5 {
                        Text("Only \(remaining) spots left!")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("\(remaining)/\(capacity) spots available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 180)
    }
    
    // Helper function to format date in a readable format
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // If today, show just time
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "E, MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // Helper function to get an appropriate emoji based on age range
    private func ageRangeEmoji(for ageRange: String) -> String {
        if ageRange.contains("0-1") {
            return "👶"
        } else if ageRange.contains("All ages") {
            return "👨‍👩‍👧‍👦"
        } else if ageRange.lowercased().contains("year") && Int(ageRange.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0 < 5 {
            return "🧒"
        } else {
            return "👧"
        }
    }
}

// Event Detail View
struct EventDetailView: View {
    let event: EventItem
    @State private var isAddedToCalendar = false
    @State private var showingJoinConfirmation = false
    @State private var hasJoined = false
    @State private var showingFullMapView = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header banner
                ZStack(alignment: .bottom) {
                    // Event banner background
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Text(ageRangeEmoji(for: event.ageRange))
                                .font(.system(size: 80))
                        )
                    
                    // Age range indicator
                    HStack {
                        Text(event.ageRange)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        // Price tag
                        if event.isPaid {
                            Text("$\(event.price?.formatted() ?? "Paid")")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.green)
                                .cornerRadius(8)
                        } else {
                            Text("Free")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    // Event title and details
                    VStack(alignment: .leading, spacing: 10) {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Date information with icon
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text(formatDate(event.date))
                                .foregroundColor(.secondary)
                        }
                        
                        // Location information with icon
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text(event.location)
                                .foregroundColor(.secondary)
                        }
                        
                        // Distance information
                        if let distance = event.distance {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                Text("\(String(format: "%.1f", distance)) miles from your location")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Capacity information
                        if let capacity = event.capacity, let remaining = event.spotsRemaining {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                if remaining > 0 {
                                    if remaining < 5 {
                                        Text("Only \(remaining) of \(capacity) spots remaining!")
                                            .foregroundColor(.orange)
                                    } else {
                                        Text("\(remaining) of \(capacity) spots available")
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Event is full")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Created by information
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text("Added by: \(event.createdBy)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    // Event description
                    Text("About this event")
                        .font(.headline)
                    
                    Text(event.description)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Map view for event location
                    VStack(alignment: .leading) {
                        Text("Location")
                            .font(.headline)
                        
                        // Interactive map
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: event.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: [event]) { event in
                            MapAnnotation(coordinate: event.coordinate) {
                                VStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(Color("AppPrimaryColor"))
                                        .font(.title)
                                    
                                    Text(event.title)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                        .frame(height: 150)
                        .cornerRadius(10)
                        .onTapGesture {
                            showingFullMapView = true
                        }
                    }
                    
                    // Action buttons
                    HStack {
                        // Join Event button
                        if let remaining = event.spotsRemaining, remaining > 0 || event.capacity == nil {
                            Button(action: {
                                if !hasJoined {
                                    showingJoinConfirmation = true
                                } else {
                                    hasJoined = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: hasJoined ? "person.badge.minus" : "person.badge.plus")
                                    Text(hasJoined ? "Leave Event" : "Join Event")
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(hasJoined ? Color.red : Color("AppPrimaryColor"))
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            .alert("Join this event?", isPresented: $showingJoinConfirmation) {
                                Button("Cancel", role: .cancel) { }
                                Button("Join") {
                                    hasJoined = true
                                }
                            } message: {
                                if event.isPaid {
                                    Text("This event costs $\(event.price?.formatted() ?? ""). You will need to pay at the event.")
                                } else {
                                    Text("You'll be added to the attendee list for this event.")
                                }
                            }
                        } else {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Event Full")
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            .disabled(true)
                        }
                        
                        Spacer()
                        
                        // Add to calendar button
                        Button(action: {
                            isAddedToCalendar.toggle()
                        }) {
                            HStack {
                                Image(systemName: isAddedToCalendar ? "calendar.badge.checkmark" : "calendar.badge.plus")
                                Text(isAddedToCalendar ? "Added" : "Add to Calendar")
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(25)
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing:
            Button(action: {
                // Share event action
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        )
        .sheet(isPresented: $showingFullMapView) {
            // Full map view
            NavigationView {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: event.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )), annotationItems: [event]) { event in
                    MapMarker(coordinate: event.coordinate, tint: Color("AppPrimaryColor"))
                }
                .edgesIgnoringSafeArea(.all)
                .navigationTitle(event.title)
                .navigationBarItems(trailing: Button("Done") {
                    showingFullMapView = false
                })
            }
        }
    }
    
    // Helper function to format date in a readable format
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to get an appropriate emoji based on age range
    private func ageRangeEmoji(for ageRange: String) -> String {
        if ageRange.contains("0-1") {
            return "👶"
        } else if ageRange.contains("All ages") {
            return "👨‍👩‍👧‍👦"
        } else if ageRange.lowercased().contains("year") && Int(ageRange.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0 < 5 {
            return "🧒"
        } else {
            return "👧"
        }
    }
}

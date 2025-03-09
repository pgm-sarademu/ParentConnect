import SwiftUI
import CoreData
import MapKit

struct EventsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var events: [EventPreview] = []
    @State private var searchText = ""
    @State private var showingAddEventSheet = false
    @State private var showingFilters = false
    @State private var filters = EventFilters()
    @State private var showingProfileView = false
    
    // Mock user data for ordering by age relevance
    @State private var userChildAges = [4, 6]  // Would come from user profile in a real app
    
    var filteredEvents: [EventPreview] {
        var filtered = events
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply date filter
        switch filters.selectedDateRange {
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        case .thisWeek:
            let today = Calendar.current.startOfDay(for: Date())
            guard let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: today) else {
                break
            }
            filtered = filtered.filter { $0.date >= today && $0.date <= oneWeekLater }
        case .thisMonth:
            let today = Calendar.current.startOfDay(for: Date())
            guard let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: today) else {
                break
            }
            filtered = filtered.filter { $0.date >= today && $0.date <= oneMonthLater }
        default:
            break // All events
        }
        
        // Apply price filter - in real app, would need to check Event entity's isPaid field
        switch filters.priceFilter {
        case .free:
            // For demo, we're just checking even/odd IDs to simulate free/paid events
            filtered = filtered.filter {
                let idNumber = Int($0.id) ?? 0
                return idNumber % 2 == 0 // Even IDs are "free" for demo
            }
        case .paid:
            // For demo, we're just checking even/odd IDs to simulate free/paid events
            filtered = filtered.filter {
                let idNumber = Int($0.id) ?? 0
                return idNumber % 2 != 0 // Odd IDs are "paid" for demo
            }
        default:
            break // All events
        }
        
        // Apply age filter - in real app, we would check the Event entity's ageRange property
        if filters.ageFilter != "All Ages" {
            // This is just a simulation filter - in a real app we would parse the age range properly
            filtered = filtered.filter { event in
                // For demo, filter based on ID length to simulate different age ranges
                let idLength = event.id.count
                
                switch filters.ageFilter {
                case "0-2 years":
                    return idLength == 1
                case "3-5 years":
                    return idLength == 2
                case "6-8 years":
                    return idLength == 3
                case "9-12 years":
                    return idLength == 4
                case "Teenagers":
                    return idLength >= 5
                default:
                    return true
                }
            }
        }
        
        // Apply distance filter based on selected location
        if filters.distanceFilter != .any {
            // Get the reference location (either current or custom)
            let referenceLocation: CLLocation?
            
            switch filters.customLocation {
            case .currentLocation:
                referenceLocation = locationManager.location
            case .customLocation(let location, _):
                referenceLocation = location
            }
            
            if let referenceLocation = referenceLocation {
                filtered = filtered.filter { event in
                    // In a real app, you would use actual event coordinates
                    // For demo, simulate with mock coordinates
                    let eventCoord = getMockCoordinates(for: event)
                    let eventLocation = CLLocation(latitude: eventCoord.latitude, longitude: eventCoord.longitude)
                    
                    // Calculate distance in miles
                    let distanceInMeters = referenceLocation.distance(from: eventLocation)
                    let distanceInMiles = distanceInMeters * 0.000621371 // Convert meters to miles
                    
                    return distanceInMiles <= filters.distanceFilter.distance
                }
            }
        }
        
        // Sort by date, location proximity, and child age relevance
        return dateBasedSort(filtered)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom title with profile button
                HStack {
                    Text("Events")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        showingProfileView = true
                    }) {
                        Image(systemName: "person")
                            .foregroundColor(Color("AppPrimaryColor"))
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Custom search and filter bar
                HStack {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search events", text: $searchText)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Filter button
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    .padding(.leading, 8)
                    
                    // Add Event button (just + icon)
                    Button(action: {
                        showingAddEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    .padding(.leading, 8)
                }
                .padding()
                
                // Active filter tags
                HStack(spacing: 8) {
                    if activeFilterCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("\(activeFilterCount) active")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if filters.priceFilter != .all {
                                FilterTag(text: filters.priceFilter.rawValue) {
                                    filters.priceFilter = .all
                                }
                            }
                            
                            if filters.ageFilter != "All Ages" {
                                FilterTag(text: filters.ageFilter) {
                                    filters.ageFilter = "All Ages"
                                }
                            }
                            
                            if filters.selectedDateRange != .all {
                                FilterTag(text: filters.selectedDateRange.rawValue) {
                                    filters.selectedDateRange = .all
                                }
                            }
                            
                            if filters.distanceFilter != .any {
                                FilterTag(text: filters.distanceFilter.rawValue) {
                                    filters.distanceFilter = .any
                                }
                            }
                            
                            if case let .customLocation(_, name) = filters.customLocation {
                                FilterTag(text: "📍 \(name)") {
                                    filters.customLocation = .currentLocation
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if activeFilterCount > 0 {
                        Button(action: {
                            resetFilters()
                        }) {
                            Text("Clear")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
                
                if filteredEvents.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "calendar.badge.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No events found")
                            .font(.headline)
                        
                        if case let .customLocation(_, name) = filters.customLocation {
                            Text("No events found in \(name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Try changing your filters or check back later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button(action: {
                            resetFilters()
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
                        
                        Button(action: {
                            showingAddEventSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create an Event")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(20)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                } else {
                    // Display location header if using custom location
                    if case let .customLocation(_, name) = filters.customLocation {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text("Showing events near \(name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    
                    // Event Grid Layout
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 15)], spacing: 15) {
                            ForEach(filteredEvents) { event in
                                NavigationLink {
                                    EventDetail(event: event)
                                } label: {
                                    EventCardView(event: event)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
            }
            .onAppear {
                loadMockEvents()
                loadUserProfile()
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .sheet(isPresented: $showingFilters) {
                EventFiltersView(filters: $filters, isPresented: $showingFilters)
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
            }
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filters.priceFilter != .all { count += 1 }
        if filters.ageFilter != "All Ages" { count += 1 }
        if filters.selectedDateRange != .all { count += 1 }
        if filters.distanceFilter != .any { count += 1 }
        if case .customLocation = filters.customLocation { count += 1 }
        return count
    }
    
    private func resetFilters() {
        filters = EventFilters()
    }
    
    // Load user profile data
    private func loadUserProfile() {
        // In a real app, this would come from Core Data or user preferences
        userChildAges = [4, 6]
    }
    
    // Date-based sorting (simplified)
    private func dateBasedSort(_ events: [EventPreview]) -> [EventPreview] {
        events.sorted { e1, e2 in
            let days1 = daysBetween(Date(), e1.date)
            let days2 = daysBetween(Date(), e2.date)
            
            // Events happening sooner come first
            return days1 < days2
        }
    }
    
    // Calculate days between two dates
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    // Create mock coordinates for distance calculations
    private func getMockCoordinates(for event: EventPreview) -> CLLocationCoordinate2D {
        // Base coordinates
        let baseLatitude = locationManager.location?.coordinate.latitude ?? 37.7749
        let baseLongitude = locationManager.location?.coordinate.longitude ?? -122.4194
        
        // Simple offset based on event ID
        let idHash = event.id.hash
        let latitudeOffset = Double(abs(idHash % 100)) * 0.0003
        let longitudeOffset = Double(abs((idHash / 100) % 100)) * 0.0003
        
        // Direction
        let latSign = (idHash & 1) == 0 ? 1.0 : -1.0
        let lonSign = (idHash & 2) == 0 ? 1.0 : -1.0
        
        return CLLocationCoordinate2D(
            latitude: baseLatitude + (latitudeOffset * latSign),
            longitude: baseLongitude + (longitudeOffset * lonSign)
        )
    }
    
    private func loadMockEvents() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        events = [
            EventPreview(
                id: "1",
                title: "Storytime at Library",
                date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
                location: "Central Library"
            ),
            EventPreview(
                id: "2",
                title: "Park Playdate",
                date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate,
                location: "Sunshine Park"
            ),
            EventPreview(
                id: "3",
                title: "Kids Art Class",
                date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                location: "Community Center"
            ),
            EventPreview(
                id: "4",
                title: "Family Movie Night",
                date: calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate,
                location: "City Theater"
            ),
            EventPreview(
                id: "5",
                title: "Swimming Lessons",
                date: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                location: "Community Pool"
            ),
            EventPreview(
                id: "6",
                title: "Parent Support Group",
                date: calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate,
                location: "Family Center"
            ),
            EventPreview(
                id: "7",
                title: "Toddler Gymnastics",
                date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate,
                location: "Kids Gym Center"
            ),
            EventPreview(
                id: "8",
                title: "Science Workshop for Kids",
                date: calendar.date(byAdding: .day, value: 6, to: currentDate) ?? currentDate,
                location: "Science Museum"
            ),
            EventPreview(
                id: "9",
                title: "Outdoor Adventure Day",
                date: calendar.date(byAdding: .day, value: 9, to: currentDate) ?? currentDate,
                location: "Nature Reserve"
            ),
            EventPreview(
                id: "10",
                title: "Music Class for Kids",
                date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                location: "Music School"
            ),
            EventPreview(
                id: "11",
                title: "Coding for Teens",
                date: calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate,
                location: "Tech Learning Center"
            ),
            EventPreview(
                id: "12",
                title: "Puppet Show",
                date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
                location: "Children's Theater"
            )
        ]
    }
}

// Card view for events in the grid
struct EventCardView: View {
    let event: EventPreview
    
    // In a real app, these would be calculated from your data model
    let hasActiveChat: Bool = Bool.random() // Randomly show chat indicator in preview
    let chatParticipantCount: Int = Int.random(in: 2...15)
    let unreadChatMessages: Int = Int.random(in: 0...5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event image with date overlay
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay(
                        Text("🎪")
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
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(formatTime(event.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(event.location)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Age recommendation - simulated based on ID for demo
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    // Generate a simulated age range based on event ID
                    let minAge = (Int(event.id) ?? 0) % 15 + 1
                    Text("Ages \(minAge)-\(minAge+3)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Chat information row
                if hasActiveChat {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("\(chatParticipantCount) in chat")
                            .font(.system(size: 12))
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        if unreadChatMessages > 0 {
                            Text("• \(unreadChatMessages) new")
                                .font(.system(size: 12))
                                .foregroundColor(Color("AppPrimaryColor"))
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .foregroundColor(.primary) // Ensure text isn't blue when in a NavigationLink
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper functions - these would normally be extensions or utilities
func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func formatDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date)
}

func formatDayNumber(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
}

func formatMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
}

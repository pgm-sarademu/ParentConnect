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
        
        // Sort by location proximity and age relevance (instead of just date)
        return sortByRelevance(events: filtered)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter summary bar
                HStack(spacing: 12) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                            Text("Filters")
                                .font(.system(size: 15, weight: .medium))
                            
                            // Shows active filter count
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 22, height: 22)
                                    .background(Color("AppPrimaryColor"))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    
                    // Active filter tags
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
                    // Display info about sorting at the top
                    HStack {
                        Text("Events sorted by location and child age relevance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 2)
                    
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
                    
                    List {
                        ForEach(filteredEvents) { event in
                            NavigationLink(destination: EnhancedEventDetailView(event: event)) {
                                // Use the enhanced row without star indicators
                                EventListRowSimplified(event: event)
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
            .onAppear {
                loadMockEvents()
                loadUserProfile()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .sheet(isPresented: $showingFilters) {
                EventFiltersView(filters: $filters, isPresented: $showingFilters)
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
        // For demo, we'll use mock data
        userChildAges = [4, 6]
    }
    
    // Calculate a relevance score for each event
    private func calculateRelevanceScore(for event: EventPreview) -> Double {
        var score = 0.0
        
        // 1. Location proximity (0-100 points)
        let distance = getDistanceToEvent(event)
        
        // Closer events get higher scores
        if distance < 1.0 {
            score += 100 // Very close
        } else if distance < 3.0 {
            score += 80
        } else if distance < 5.0 {
            score += 60
        } else if distance < 10.0 {
            score += 40
        } else if distance < 20.0 {
            score += 20
        }
        
        // 2. Age relevance (0-100 points)
        // In a real app, parse age ranges from the event
        // For demo, use the event ID to simulate age ranges
        let idNumber = Int(event.id) ?? 0
        let eventAgeMin = (idNumber % 15) + 1 // 1-15 years
        let eventAgeMax = eventAgeMin + 3
        
        // Check how well user's children's ages match the event's age range
        for childAge in userChildAges {
            if childAge >= eventAgeMin && childAge <= eventAgeMax {
                // Perfect age match
                score += 100 / Double(userChildAges.count)
            } else if abs(childAge - eventAgeMin) <= 1 || abs(childAge - eventAgeMax) <= 1 {
                // Close age match (within 1 year)
                score += 60 / Double(userChildAges.count)
            } else if abs(childAge - eventAgeMin) <= 2 || abs(childAge - eventAgeMax) <= 2 {
                // Somewhat close (within 2 years)
                score += 30 / Double(userChildAges.count)
            }
        }
        
        // 3. Date relevance (0-50 points)
        // Events happening soon get higher scores
        let daysUntilEvent = daysBetween(Date(), event.date)
        if daysUntilEvent == 0 {
            score += 50 // Today
        } else if daysUntilEvent <= 2 {
            score += 40 // Next couple days
        } else if daysUntilEvent <= 7 {
            score += 30 // This week
        } else if daysUntilEvent <= 14 {
            score += 20 // Next 2 weeks
        } else if daysUntilEvent <= 30 {
            score += 10 // This month
        }
        
        return score
    }
    
    // Sort events by their relevance score
    private func sortByRelevance(events: [EventPreview]) -> [EventPreview] {
        return events.sorted { (event1, event2) -> Bool in
            let score1 = calculateRelevanceScore(for: event1)
            let score2 = calculateRelevanceScore(for: event2)
            return score1 > score2
        }
    }
    
    // Calculate days between two dates
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
    }
    
    // Get distance to event
    private func getDistanceToEvent(_ event: EventPreview) -> Double {
        guard let userLocation = locationManager.location else {
            return 100.0 // Default large distance if location unknown
        }
        
        // In a real app, you would use real event coordinates
        // For demo, create mock coordinates
        let coordinates = getMockCoordinates(for: event)
        let eventLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        // Calculate distance in miles
        let distanceInMeters = userLocation.distance(from: eventLocation)
        return distanceInMeters * 0.000621371 // Convert meters to miles
    }
    
    // Create mock coordinates for distance calculations
    private func getMockCoordinates(for event: EventPreview) -> CLLocationCoordinate2D {
        // In a real app, each event would have its own coordinates
        // For this demo, we'll just simulate different coordinates based on the event ID
        
        // Base coordinates - roughly around user's location
        let baseLatitude = locationManager.location?.coordinate.latitude ?? 37.7749
        let baseLongitude = locationManager.location?.coordinate.longitude ?? -122.4194
        
        // Create a deterministic "random" offset based on the event ID
        let idHash = event.id.hash
        let latitudeOffset = Double(abs(idHash % 100)) * 0.0003
        let longitudeOffset = Double(abs((idHash / 100) % 100)) * 0.0003
        
        // Use XOR to determine direction
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

// Simplified Event List Row Component without stars or relevance indicators
struct EventListRowSimplified: View {
    let event: EventPreview
    
    var body: some View {
        HStack(spacing: 15) {
            // Date component
            VStack(spacing: 2) {
                Text(formatDay(event.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formatDayNumber(event.date))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("AppPrimaryColor"))
                
                Text(formatMonth(event.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AppPrimaryColor").opacity(0.1))
            )
            
            // Event info
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(formatTime(event.date))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(event.location)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Age recommendation - simulated based on ID for demo
                // In a real app, this would come from event data
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    let minAge = (Int(event.id) ?? 0) % 15 + 1
                    Text("Ages \(minAge)-\(minAge+3)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
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
}

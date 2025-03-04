import SwiftUI
import MapKit

// Playdate model with location and privacy settings
struct Playdate: Identifiable {
    let id: String
    let parentName: String
    let location: String
    let time: Date
    let description: String
    let attendingCount: Int
    var isAttending: Bool = false
    var visibility: String = "Public" // "Public", "Friends Only", or "Invite Only"
    var invitedFriends: [String] = [] // IDs of invited friends for "Invite Only" playdates
    let coordinate: CLLocationCoordinate2D
    let distance: Double? // Distance from user's location in miles
}

// Main PlaydatesView
struct PlaydatesView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var playdates: [Playdate] = []
    @State private var showingCreatePlaydateSheet = false
    @State private var showingMapView = false
    @State private var searchText = ""
    @State private var selectedVisibility: VisibilityFilter = .all
    @State private var userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // Default to San Francisco
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    // Enum to define visibility filter options
    enum VisibilityFilter: String, CaseIterable {
        case all = "All"
        case publicFilter = "Public"  // Changed from 'public' to 'publicFilter'
        case friendsOnly = "Friends"
        case inviteOnly = "Invites"
    }
    
    // Filtered playdates based on search and visibility
    var filteredPlaydates: [Playdate] {
        var filtered = playdates
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.location.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by visibility
        switch selectedVisibility {
        case .all:
            // Show all playdates the user has access to see
            break
        case .publicFilter:  // Changed from .public
            filtered = filtered.filter { $0.visibility == "Public" }
        case .friendsOnly:
            filtered = filtered.filter { $0.visibility == "Friends Only" }
        case .inviteOnly:
            filtered = filtered.filter { $0.visibility == "Invite Only" && $0.invitedFriends.contains("current-user-id") }
        }
        
        // Sort by time (soonest first) and then by proximity
        return filtered.sorted {
            if $0.time.timeIntervalSince1970 == $1.time.timeIntervalSince1970 {
                return $0.distance ?? Double.infinity < $1.distance ?? Double.infinity
            }
            return $0.time < $1.time
        }
    }
    
    // Recommended playdates (nearby and happening soon)
    var recommendedPlaydates: [Playdate] {
        // Only include playdates happening within the next 8 hours that are nearby
        return filteredPlaydates
            .filter {
                $0.time > Date() &&
                $0.time < Date().addingTimeInterval(8 * 60 * 60) &&
                ($0.distance ?? Double.infinity) < 5.0 // Within 5 miles
            }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Map with playdate locations
                ZStack(alignment: .topTrailing) {
                    // Map with playdate markers
                    Map(coordinateRegion: $region, annotationItems: filteredPlaydates) { playdate in
                        MapAnnotation(coordinate: playdate.coordinate) {
                            VStack {
                                Image(systemName: "figure.2.and.child.holdinghands.circle.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.title)
                                    .shadow(radius: 2)
                                
                                if playdate.visibility != "Public" {
                                    Image(systemName: playdate.visibility == "Friends Only" ? "person.2.circle.fill" : "lock.circle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                        .background(Circle().fill(Color.white))
                                        .offset(x: 10, y: -10)
                                }
                                
                                Text(timeString(from: playdate.time))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                                    .shadow(radius: 1)
                            }
                            .onTapGesture {
                                // Navigate to playdate details (would need to be implemented with navigation state)
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
                
                // Visibility filter
                Picker("Visibility", selection: $selectedVisibility) {
                    ForEach(VisibilityFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Recommended playdates section (if any)
                if !recommendedPlaydates.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Happening Soon Nearby")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(recommendedPlaydates) { playdate in
                                    RecommendedPlaydateCard(playdate: playdate)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if filteredPlaydates.isEmpty {
                    // Empty state when no playdates match criteria
                    VStack(spacing: 15) {
                        Spacer()
                        Image(systemName: "figure.2.and.child.holdinghands")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No playdates found")
                            .font(.headline)
                        
                        Text("Create a playdate or adjust your filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingCreatePlaydateSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create a Playdate")
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
                    // List of playdates
                    List {
                        ForEach(filteredPlaydates) { playdate in
                            NavigationLink(destination: PlaydateDetailView(playdate: playdate)) {
                                PlaydateListItem(playdate: playdate)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Playdates")
            .navigationBarItems(trailing:
                Button(action: {
                    showingCreatePlaydateSheet = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            )
            .searchable(text: $searchText, prompt: "Search locations & descriptions")
            .sheet(isPresented: $showingCreatePlaydateSheet) {
                // Create playdate view would go here
            }
            .onAppear {
                // Update region to focus on user's location
                if let userLoc = locationManager.location?.coordinate {
                    userLocation = userLoc
                    region = MKCoordinateRegion(
                        center: userLoc,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
                
                // Load mock data
                playdates = generateMockPlaydates()
            }
        }
    }
    
    // Time formatting helper
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Generate mock playdate data
    private func generateMockPlaydates() -> [Playdate] {
        return [
            Playdate(
                id: "1",
                parentName: "Maria K.",
                location: "Sunshine Park Playground",
                time: Date().addingTimeInterval(5400), // 1.5 hours from now
                description: "My 4-year-old wants to play on the slides. Anyone want to join us?",
                attendingCount: 3,
                visibility: "Public",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
            ),
            Playdate(
                id: "2",
                parentName: "John D.",
                location: "Beach Cove",
                time: Date().addingTimeInterval(7200), // 2 hours from now
                description: "We're bringing beach toys and snacks. All ages welcome!",
                attendingCount: 2,
                visibility: "Friends Only",
                coordinate: CLLocationCoordinate2D(latitude: 37.7739, longitude: -122.4312),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7739, longitude: -122.4312))
            ),
            Playdate(
                id: "3",
                parentName: "Emma L.",
                location: "Community Center",
                time: Date().addingTimeInterval(-1800), // 30 min ago
                description: "We're here for another hour if anyone wants to join.",
                attendingCount: 4,
                visibility: "Invite Only",
                invitedFriends: ["current-user-id", "friend-2"],
                coordinate: CLLocationCoordinate2D(latitude: 37.7699, longitude: -122.4111),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7699, longitude: -122.4111))
            ),
            Playdate(
                id: "4",
                parentName: "Alex T.",
                location: "Neighborhood Playground",
                time: Date().addingTimeInterval(3600), // 1 hour from now
                description: "Casual playdate for toddlers. We have extra snacks!",
                attendingCount: 2,
                visibility: "Public",
                coordinate: CLLocationCoordinate2D(latitude: 37.7829, longitude: -122.4024),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7829, longitude: -122.4024))
            ),
            Playdate(
                id: "5",
                parentName: "Sam B.",
                location: "Indoor Play Center",
                time: Date().addingTimeInterval(10800), // 3 hours from now
                description: "Meeting at the indoor play center. Great for rainy days!",
                attendingCount: 5,
                visibility: "Public",
                coordinate: CLLocationCoordinate2D(latitude: 37.7569, longitude: -122.4148),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7569, longitude: -122.4148))
            ),
            Playdate(
                id: "6",
                parentName: "Jamie S.",
                location: "Library Kids' Area",
                time: Date().addingTimeInterval(1800), // 30 min from now
                description: "Storytime and free play at the library.",
                attendingCount: 3,
                visibility: "Friends Only",
                coordinate: CLLocationCoordinate2D(latitude: 37.7869, longitude: -122.4000),
                distance: locationManager.calculateDistance(to: CLLocationCoordinate2D(latitude: 37.7869, longitude: -122.4000))
            )
        ]
    }
}

// Component to display a playdate in the list
struct PlaydateListItem: View {
    let playdate: Playdate
    
    var body: some View {
        HStack(spacing: 15) {
            // Time indicator with color coding
            VStack(alignment: .center) {
                Text(timeString(from: playdate.time))
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .foregroundColor(timeColor(for: playdate.time))
                
                Text(dateString(from: playdate.time))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(playdate.location)
                        .font(.headline)
                    
                    Spacer()
                    
                    // Visibility indicator
                    if playdate.visibility != "Public" {
                        Image(systemName: playdate.visibility == "Friends Only" ? "person.2.circle.fill" : "lock.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(playdate.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    // Parent info
                    Image(systemName: "person.fill")
                        .foregroundColor(Color("AppPrimaryColor"))
                    Text(playdate.parentName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Attendees count
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color("AppPrimaryColor"))
                    Text("\(playdate.attendingCount) attending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let distance = playdate.distance {
                        Spacer()
                        Text("\(String(format: "%.1f", distance)) mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if playdate.isAttending {
                    HStack {
                        Spacer()
                        Text("You're going")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Time formatting helper
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Date formatting helper
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    // Color based on time
    private func timeColor(for date: Date) -> Color {
        let now = Date()
        if date < now {
            return .secondary // Past
        } else if date < now.addingTimeInterval(3600) {
            return .orange // Within the hour
        } else {
            return Color("AppPrimaryColor")
        }
    }
}

// Card for recommended playdates
struct RecommendedPlaydateCard: View {
    let playdate: Playdate
    
    var body: some View {
        VStack(alignment: .leading) {
            // Top section with time and location
            HStack {
                // Time indicator
                Text(timeString(from: playdate.time))
                    .font(.headline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(timeBackground(for: playdate.time))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
                
                // Distance
                if let distance = playdate.distance {
                    Text("\(String(format: "%.1f", distance)) mi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Location
            Text(playdate.location)
                .font(.headline)
                .lineLimit(1)
                .padding(.top, 4)
            
            // Description
            Text(playdate.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.top, 1)
            
            Spacer()
            
            // Bottom info
            HStack {
                // Host info
                Text("by \(playdate.parentName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Attendees count with icon
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color("AppPrimaryColor"))
                    .font(.caption)
                Text("\(playdate.attendingCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Privacy indicator
                if playdate.visibility != "Public" {
                    Image(systemName: playdate.visibility == "Friends Only" ? "person.2.circle.fill" : "lock.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(width: 250, height: 150)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Time formatting helper
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "E, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // Background color based on time
    private func timeBackground(for date: Date) -> Color {
        let now = Date()
        if date < now {
            return .gray // Past
        } else if date < now.addingTimeInterval(3600) {
            return .orange // Within the hour
        } else {
            return Color("AppPrimaryColor")
        }
    }
}

// Playdate detail view
struct PlaydateDetailView: View {
    let playdate: Playdate
    @State private var isAttending = false
    @State private var showingFullMapView = false
    @State private var showingJoinConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map view
                ZStack(alignment: .bottomTrailing) {
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: playdate.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [playdate]) { playdate in
                        MapAnnotation(coordinate: playdate.coordinate) {
                            Image(systemName: "figure.2.and.child.holdinghands.circle.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                                .font(.title)
                        }
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .onTapGesture {
                        showingFullMapView = true
                    }
                    
                    // Expand map button
                    Button(action: {
                        showingFullMapView = true
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("AppPrimaryColor"))
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    // Time and location header
                    HStack {
                        // Time indicator
                        VStack(alignment: .center) {
                            Text(timeString(from: playdate.time))
                                .font(.title2)
                                .foregroundColor(timeColor(for: playdate.time))
                            
                            Text(dateString(from: playdate.time))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Privacy indicator
                        VStack(alignment: .center) {
                            Image(systemName: privacyIcon(for: playdate.visibility))
                                .font(.title2)
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(playdate.visibility)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text(playdate.location)
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Distance if available
                    if let distance = playdate.distance {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("\(String(format: "%.1f", distance)) miles from your location")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(playdate.description)
                        .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Host information
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("Hosted by \(playdate.parentName)")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    
                    // Attendees information
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("\(playdate.attendingCount) parents & kids attending")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button(action: {
                            // Show attendees list
                        }) {
                            Text("See who's going")
                                .font(.caption)
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Join/Leave button
                    Button(action: {
                        if !isAttending {
                            showingJoinConfirmation = true
                        } else {
                            isAttending = false
                        }
                    }) {
                        HStack {
                            Spacer()
                            
                            if isAttending {
                                Label("I Can't Make It", systemImage: "xmark.circle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            } else {
                                Label("I'll Be There", systemImage: "checkmark.circle")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(isAttending ? Color.red : Color("AppPrimaryColor"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .alert("Join this playdate?", isPresented: $showingJoinConfirmation) {
                        Button("Cancel", role: .cancel) { }
                        Button("Join") {
                            isAttending = true
                        }
                    } message: {
                        Text("You'll be added to the list of attendees for this playdate at \(playdate.location).")
                    }
                    
                    // Share button
                    Button(action: {
                        // Share action
                    }) {
                        HStack {
                            Spacer()
                            
                            Label("Invite Friends", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color("AppPrimaryColor").opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .onAppear {
                isAttending = playdate.isAttending
            }
        }
        .navigationTitle("Playdate Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFullMapView) {
            // Full map view
            NavigationView {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: playdate.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )), annotationItems: [playdate]) { playdate in
                    MapMarker(coordinate: playdate.coordinate, tint: Color("AppPrimaryColor"))
                }
                .edgesIgnoringSafeArea(.all)
                .navigationTitle(playdate.location)
                .navigationBarItems(trailing: Button("Done") {
                    showingFullMapView = false
                })
            }
        }
    }
    
    // Time formatting helper
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Date formatting helper
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "E, MMM d"
            return formatter.string(from: date)
        }
    }
    
    // Color based on time
    private func timeColor(for date: Date) -> Color {
        let now = Date()
        if date < now {
            return .secondary // Past
        } else if date < now.addingTimeInterval(3600) {
            return .orange // Within the hour
        } else {
            return Color("AppPrimaryColor")
        }
    }
    
    // Icon for privacy level
    private func privacyIcon(for visibility: String) -> String {
        switch visibility {
        case "Friends Only":
            return "person.2.circle.fill"
        case "Invite Only":
            return "lock.circle.fill"
        default:
            return "globe"
        }
    }
}

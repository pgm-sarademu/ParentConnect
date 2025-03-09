import SwiftUI
import CoreData
import MapKit

struct Playdates: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var playdates: [PlaydatePreview] = []
    @State private var searchText = ""
    @State private var showingAddPlaydateSheet = false
    @State private var showingFilters = false
    @State private var filters = PlaydateFilters()
    @State private var showingProfileView = false
    
    var filteredPlaydates: [PlaydatePreview] {
        var filtered = playdates
        
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
            break // All playdates
        }
        
        // Apply age filter
        if filters.ageFilter != "All Ages" {
            filtered = filtered.filter { playdate in
                // Sample implementation - in a real app you'd check actual age ranges
                switch filters.ageFilter {
                case "0-2 years":
                    return playdate.id.hasPrefix("1")
                case "3-5 years":
                    return playdate.id.hasPrefix("2")
                case "6-8 years":
                    return playdate.id.hasPrefix("3")
                case "9-12 years":
                    return playdate.id.hasPrefix("4")
                default:
                    return true
                }
            }
        }
        
        // Apply distance filter
        if filters.distanceFilter != .any {
            if let userLocation = locationManager.location {
                filtered = filtered.filter { playdate in
                    // Sample implementation - in a real app you'd use actual coordinates
                    let playdateLocation = getMockCoordinates(for: playdate)
                    let playdateCoord = CLLocation(latitude: playdateLocation.latitude, longitude: playdateLocation.longitude)
                    
                    let distanceInMeters = userLocation.distance(from: playdateCoord)
                    let distanceInMiles = distanceInMeters * 0.000621371 // Convert to miles
                    
                    return distanceInMiles <= filters.distanceFilter.distance
                }
            }
        }
        
        // Apply location filter
        if case let .customLocation(customLocation, _) = filters.customLocation {
            filtered = filtered.filter { playdate in
                let playdateLocation = getMockCoordinates(for: playdate)
                let playdateCoord = CLLocation(latitude: playdateLocation.latitude, longitude: playdateLocation.longitude)
                
                let distanceInMeters = customLocation.distance(from: playdateCoord)
                let distanceInMiles = distanceInMeters * 0.000621371 // Convert to miles
                
                return distanceInMiles <= filters.distanceFilter.distance
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom title with profile button
                HStack {
                    Text("Playdates")
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
                        TextField("Search playdates", text: $searchText)
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
                    
                    // Add Playdate button
                    Button(action: {
                        showingAddPlaydateSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    .padding(.leading, 8)
                }
                .padding()
                
                // Active filter tags
                if countActiveFilters() > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if countActiveFilters() > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color("AppPrimaryColor"))
                                    
                                    Text("\(countActiveFilters()) active")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color("AppPrimaryColor"))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                            }
                            
                            if filters.selectedDateRange != .all {
                                PlaydateFilterTag(text: filters.selectedDateRange.rawValue) {
                                    filters.selectedDateRange = .all
                                }
                            }
                            
                            if filters.ageFilter != "All Ages" {
                                PlaydateFilterTag(text: filters.ageFilter) {
                                    filters.ageFilter = "All Ages"
                                }
                            }
                            
                            if filters.distanceFilter != .any {
                                PlaydateFilterTag(text: filters.distanceFilter.rawValue) {
                                    filters.distanceFilter = .any
                                }
                            }
                            
                            if case let .customLocation(_, name) = filters.customLocation {
                                PlaydateFilterTag(text: "📍 \(name)") {
                                    filters.customLocation = .currentLocation
                                }
                            }
                            
                            Spacer()
                            
                            if countActiveFilters() > 0 {
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
                    }
                    .padding(.bottom, 8)
                }
                
                if filteredPlaydates.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.3.sequence.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(Color(.systemGray4))
                        
                        Text("No playdates found")
                            .font(.headline)
                        
                        if case let .customLocation(_, name) = filters.customLocation {
                            Text("No playdates found near \(name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Try changing your filters or create a new playdate")
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
                            showingAddPlaydateSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create a Playdate")
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
                            Text("Showing playdates near \(name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    
                    // Playdate Grid Layout
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 15)], spacing: 15) {
                            ForEach(filteredPlaydates) { playdate in
                                NavigationLink {
                                    PlaydateDetailView(playdate: playdate)
                                } label: {
                                    PlaydateCard(playdate: playdate)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
            }
            .onAppear {
                loadMockPlaydates()
            }
            .sheet(isPresented: $showingAddPlaydateSheet) {
                AddPlaydate()
            }
            .sheet(isPresented: $showingFilters) {
                PlaydateFiltersView(filters: $filters, isPresented: $showingFilters)
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
            }
        }
    }
    
    // Helper function to get the count of active filters
    private func countActiveFilters() -> Int {
        var count = 0
        if filters.selectedDateRange != .all { count += 1 }
        if filters.ageFilter != "All Ages" { count += 1 }
        if filters.distanceFilter != .any { count += 1 }
        if case .customLocation = filters.customLocation { count += 1 }
        return count
    }
    
    private func resetFilters() {
        filters = PlaydateFilters()
    }
    
    // Mock coordinates for playdates
    private func getMockCoordinates(for playdate: PlaydatePreview) -> CLLocationCoordinate2D {
        // Base coordinates - in a real app, you'd use actual stored coordinates
        let baseLocation = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Generate a small random offset based on playdate.id to differentiate the markers
        if let idNum = Int(playdate.id) {
            let latOffset = Double(idNum % 10) * 0.002
            let longOffset = Double((idNum * 3) % 10) * 0.002
            return CLLocationCoordinate2D(
                latitude: baseLocation.latitude + latOffset,
                longitude: baseLocation.longitude + longOffset
            )
        }
        
        return baseLocation
    }
    
    private func loadMockPlaydates() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        playdates = [
            PlaydatePreview(
                id: "101",
                title: "Playground Meetup",
                date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate,
                location: "Sunshine Park Playground",
                ageRange: "3-5 years",
                hostName: "Sarah Johnson"
            ),
            PlaydatePreview(
                id: "202",
                title: "Swimming Pool Fun",
                date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                location: "Community Pool",
                ageRange: "4-6 years",
                hostName: "Michael Brown"
            ),
            PlaydatePreview(
                id: "303",
                title: "Library Play Corner",
                date: calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate,
                location: "Central Library Kids Area",
                ageRange: "2-4 years",
                hostName: "Emma Wilson"
            ),
            PlaydatePreview(
                id: "404",
                title: "Nature Walk & Play",
                date: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                location: "Forest Park Trail",
                ageRange: "6-8 years",
                hostName: "David Miller"
            ),
            PlaydatePreview(
                id: "505",
                title: "Indoor Playground Meetup",
                date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
                location: "Kidz Fun Zone",
                ageRange: "2-5 years",
                hostName: "Jennifer Davis"
            ),
            PlaydatePreview(
                id: "606",
                title: "Beach Day Sandcastle Building",
                date: calendar.date(byAdding: .day, value: 6, to: currentDate) ?? currentDate,
                location: "Sunny Beach",
                ageRange: "3-7 years",
                hostName: "Robert Garcia"
            )
        ]
    }
}

// Model for playdate preview
struct PlaydatePreview: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
    let ageRange: String
    let hostName: String
}

// Card view for playdates in the grid
struct PlaydateCard: View {
    let playdate: PlaydatePreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Playdate image with date overlay
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay(
                        Text("🧩")
                            .font(.system(size: 40))
                    )
                
                // Date badge overlay
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text(playdateFormatDay(playdate.date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(playdateFormatDayNumber(playdate.date))
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
                Text(playdate.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(playdateFormatTime(playdate.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(playdate.location)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Age range
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(playdate.ageRange)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Host name
                HStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text("Host: \(playdate.hostName)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
        return playdateFormatDay(date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        return playdateFormatDayNumber(date)
    }
    
    private func formatTime(_ date: Date) -> String {
        return playdateFormatTime(date)
    }
}

// MARK: - Filter models and views

struct PlaydateFilters {
    var selectedDateRange: DateRangeFilter = .all
    var ageFilter: String = "All Ages"
    var distanceFilter: DistanceFilter = .any
    var customLocation: LocationOption = .currentLocation
    
    enum DateRangeFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    enum DistanceFilter: String, CaseIterable {
        case any = "Any Distance"
        case nearby = "Nearby (<2 miles)"
        case walking = "Walking (0.5 miles)"
        case driving = "Short Drive (5 miles)"
        case local = "Local Area (10 miles)"
        
        var distance: Double {
            switch self {
            case .any: return Double.infinity
            case .nearby: return 2.0
            case .walking: return 0.5
            case .driving: return 5.0
            case .local: return 10.0
            }
        }
    }
    
    enum LocationOption: Equatable {
        case currentLocation
        case customLocation(CLLocation, String)
        
        var title: String {
            switch self {
            case .currentLocation:
                return "Current Location"
            case .customLocation(_, let name):
                return name
            }
        }
        
        var coordinate: CLLocationCoordinate2D? {
            switch self {
            case .currentLocation:
                return nil // Will use device's location
            case .customLocation(let location, _):
                return location.coordinate
            }
        }
    }
}

// Filter tag component for displaying selected filters
struct PlaydateFilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color("AppPrimaryColor").opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color("AppPrimaryColor").opacity(0.15))
        )
        .foregroundColor(Color("AppPrimaryColor"))
    }
}

// Filter chip component
struct PlaydateFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    Color("AppPrimaryColor") :
                    Color(.systemGray6)
                )
                .foregroundColor(
                    isSelected ? .white : .primary
                )
                .cornerRadius(20)
                .animation(.spring(), value: isSelected)
        }
    }
}

// Simplified Location search result for playdates
struct PlaydateLocationSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

// Simplified LocationSearchView
struct LocationSearchViewSimplified: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var customLocation: PlaydateFilters.LocationOption
    @Binding var searchQuery: String
    @Binding var searchResults: [PlaydateLocationSearchResult]
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        NavigationView {
            VStack {
                // Use current location option
                Button(action: {
                    customLocation = .currentLocation
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                        Text("Use Current Location")
                            .foregroundColor(.primary)
                        Spacer()
                        
                        // Check if current location is selected
                        if case .currentLocation = customLocation {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // Search bar
                TextField("Search for a city or location", text: $searchQuery)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onChange(of: searchQuery) { _, newValue in
                        if !newValue.isEmpty && newValue.count > 2 {
                            searchLocation(query: newValue)
                        }
                    }
                
                // Results list
                List {
                    ForEach(searchResults) { result in
                        Button(action: {
                            selectLocation(result)
                        }) {
                            VStack(alignment: .leading) {
                                Text(result.name)
                                    .font(.headline)
                                Text(result.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose Location")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Search for locations
    private func searchLocation(query: String) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        
        // Get region from location manager or use default
        let userLocation = locationManager.location?.coordinate ??
                          CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        searchRequest.region = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                }
                return
            }
            
            // Map response to our result model
            searchResults = response.mapItems.map { item in
                PlaydateLocationSearchResult(
                    name: item.name ?? "Unknown Location",
                    address: parseAddress(from: item.placemark),
                    coordinate: item.placemark.coordinate
                )
            }
        }
    }
    
    // Format address from placemark
    private func parseAddress(from placemark: MKPlacemark) -> String {
        var addressComponents = [String]()
        
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    // Handle location selection
    private func selectLocation(_ result: PlaydateLocationSearchResult) {
        let location = CLLocation(latitude: result.coordinate.latitude,
                                longitude: result.coordinate.longitude)
        customLocation = .customLocation(location, "\(result.name), \(result.address)")
        presentationMode.wrappedValue.dismiss()
    }
}

// Filters view
struct PlaydateFiltersView: View {
    @Binding var filters: PlaydateFilters
    @Binding var isPresented: Bool
    @State private var tempFilters: PlaydateFilters
    @State private var showingLocationSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [PlaydateLocationSearchResult] = []
    @EnvironmentObject var locationManager: LocationManager
    
    let ageRanges = ["All Ages", "0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers"]
    
    init(filters: Binding<PlaydateFilters>, isPresented: Binding<Bool>) {
        self._filters = filters
        self._isPresented = isPresented
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Age range filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Age Range")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ageRanges, id: \.self) { range in
                                PlaydateFilterChip(
                                    title: range,
                                    isSelected: tempFilters.ageFilter == range,
                                    action: {
                                        tempFilters.ageFilter = range
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Date filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("When")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PlaydateFilters.DateRangeFilter.allCases, id: \.self) { option in
                                PlaydateFilterChip(
                                    title: option.rawValue,
                                    isSelected: tempFilters.selectedDateRange == option,
                                    action: {
                                        tempFilters.selectedDateRange = option
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Location filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Location")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showingLocationSearch = true
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(tempFilters.customLocation.title)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Distance filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Distance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PlaydateFilters.DistanceFilter.allCases, id: \.self) { option in
                                PlaydateFilterChip(
                                    title: option.rawValue,
                                    isSelected: tempFilters.distanceFilter == option,
                                    action: {
                                        tempFilters.distanceFilter = option
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                Spacer()
                
                // Bottom button section with clear and apply buttons
                VStack {
                    // Line showing active filter count
                    HStack {
                        let count = countActiveFilters()
                        Text("\(count) \(count == 1 ? "filter" : "filters") applied")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Action buttons
                    HStack(spacing: 15) {
                        // Reset filters button
                        Button(action: {
                            tempFilters = PlaydateFilters()
                        }) {
                            Text("Reset")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                        
                        // Apply filters button
                        Button(action: {
                            filters = tempFilters
                            isPresented = false
                        }) {
                            Text("Show Results")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("AppPrimaryColor"))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("Filter Playdates")
            .navigationBarItems(
                trailing: Button("Close") {
                    isPresented = false
                }
            )
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchViewSimplified(
                    customLocation: $tempFilters.customLocation,
                    searchQuery: $searchQuery,
                    searchResults: $searchResults,
                    locationManager: locationManager
                )
            }
        }
    }
    
    // Helper function to count active filters
    private func countActiveFilters() -> Int {
        var count = 0
        if tempFilters.selectedDateRange != .all { count += 1 }
        if tempFilters.ageFilter != "All Ages" { count += 1 }
        if tempFilters.distanceFilter != .any { count += 1 }
        if case .customLocation = tempFilters.customLocation { count += 1 }
        return count
    }
}

// MARK: - Playdate Detail View

struct PlaydateDetailView: View {
    let playdate: PlaydatePreview
    @State private var isAttending = false
    @State private var showingShareSheet = false
    @State private var showingAttendees = false
    
    // Sample description
    let playdateDescription = "Join us for a fun playdate where kids can socialize and play together. Activities will include crafts, games, and outdoor play if weather permits. Parents are encouraged to stay and connect with other parents!"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event image/banner
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    Text("🧩")
                        .font(.system(size: 80))
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Title and info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(playdate.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatFullDate(playdate.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(playdateFormatTime(playdate.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(playdate.location)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Age range: \(playdate.ageRange)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Host: \(playdate.hostName)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Playdate details
                    Text("Playdate Details")
                        .font(.headline)
                    
                    Text(playdateDescription)
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
                        
                        Text("📍 \(playdate.location)")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    // Organizer info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hosted by")
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
                                Text(playdate.hostName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Parent")
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
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        return playdateFormatTime(date)
    }
}

// MARK: - Add Playdate View

struct AddPlaydate: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Form fields
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var ageRange = "3-5 years"
    @State private var maxChildrenCount = 10
    @State private var hasParticipantLimit = false
    
    // Age range options
    let ageRanges = ["0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers"]
    
    // Error handling
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Playdate Title (e.g., Park Meetup)", text: $title)
                    TextField("Location (e.g., Central Park Playground)", text: $location)
                    DatePicker("Date & Time", selection: $date)
                    
                    Picker("Age Range", selection: $ageRange) {
                        ForEach(ageRanges, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe your playdate... (e.g., Let's meet at the playground for some fun! Bring snacks if you'd like. All parents should stay with their children.)")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                }
                
                Section(header: Text("Participant Limits")) {
                    Toggle("Limit number of participants", isOn: $hasParticipantLimit)
                    
                    if hasParticipantLimit {
                        Stepper("Maximum number of children: \(maxChildrenCount)", value: $maxChildrenCount, in: 1...100)
                        
                        Text("This will limit the playdate to a maximum of \(maxChildrenCount) children total.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: savePlaydate) {
                    Text("Create Playdate")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Create Playdate")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func savePlaydate() {
        // Basic validation
        guard !title.isEmpty else {
            alertMessage = "Please enter a title"
            showingAlert = true
            return
        }
        
        guard !location.isEmpty else {
            alertMessage = "Please enter a location"
            showingAlert = true
            return
        }
        
        // Create the playdate
        // In a real app, this would save to Core Data or similar
        
        // Close the form
        presentationMode.wrappedValue.dismiss()
    }
}

// Format helper functions - these might be shared with other views
private func playdateFormatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func playdateFormatDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date)
}

private func playdateFormatDayNumber(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
}

private func playdateFormatMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
}

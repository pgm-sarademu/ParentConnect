import SwiftUI
import CoreData
import MapKit

// Model for playdate preview
struct PlaydatePreview: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
    let hostName: String
}

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
                        
                        NavigationLink(destination: AddPlaydateView()) {
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
                                    PlaydateDetail(playdate: playdate)
                                } label: {
                                    PlaydateCardView(playdate: playdate)
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
                AddPlaydateView()
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
            let latOffset = Double(abs(idNum % 100)) * 0.0003
            let longOffset = Double(abs((idNum * 3) % 100)) * 0.0003
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
                hostName: "Sarah Johnson"
            ),
            PlaydatePreview(
                id: "202",
                title: "Swimming Pool Fun",
                date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                location: "Community Pool",
                hostName: "Michael Brown"
            ),
            PlaydatePreview(
                id: "303",
                title: "Library Play Corner",
                date: calendar.date(byAdding: .day, value: 4, to: currentDate) ?? currentDate,
                location: "Central Library Kids Area",
                hostName: "Emma Wilson"
            ),
            PlaydatePreview(
                id: "404",
                title: "Nature Walk & Play",
                date: calendar.date(byAdding: .day, value: 5, to: currentDate) ?? currentDate,
                location: "Forest Park Trail",
                hostName: "David Miller"
            ),
            PlaydatePreview(
                id: "505",
                title: "Indoor Playground Meetup",
                date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate,
                location: "Kidz Fun Zone",
                hostName: "Jennifer Davis"
            ),
            PlaydatePreview(
                id: "606",
                title: "Beach Day Sandcastle Building",
                date: calendar.date(byAdding: .day, value: 6, to: currentDate) ?? currentDate,
                location: "Sunny Beach",
                hostName: "Robert Garcia"
            )
        ]
    }
}

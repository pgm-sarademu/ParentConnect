import SwiftUI
import MapKit
import CoreLocation

// MARK: - Filter models

struct PlaydateFilters {
    var selectedDateRange: DateRangeFilter = .all
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

// MARK: - Filter UI Components

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

// MARK: - Location Search

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

// MARK: - Filters View

// Filters view
struct PlaydateFiltersView: View {
    @Binding var filters: PlaydateFilters
    @Binding var isPresented: Bool
    @State private var tempFilters: PlaydateFilters
    @State private var showingLocationSearch = false
    @State private var searchQuery = ""
    @State private var searchResults: [PlaydateLocationSearchResult] = []
    @EnvironmentObject var locationManager: LocationManager
    
    init(filters: Binding<PlaydateFilters>, isPresented: Binding<Bool>) {
        self._filters = filters
        self._isPresented = isPresented
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
        if tempFilters.distanceFilter != .any { count += 1 }
        if case .customLocation = tempFilters.customLocation { count += 1 }
        return count
    }
}

import SwiftUI
import CoreData
import MapKit

// Models
struct ParentPreview: Identifiable {
    let id: String
    let name: String
    let distance: String
    let childrenInfo: String
}

struct ActivityPreview: Identifiable {
    let id: String
    let title: String
    let type: String
}

struct HomeView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var nearbyParents: [ParentPreview] = []
    @State private var featuredActivities: [ActivityPreview] = []
    @State private var upcomingEvents: [EventPreview] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map section
                ZStack(alignment: .bottom) {
                    // Fixed Map implementation
                    if #available(iOS 17.0, *) {
                        Map(initialPosition: MapCameraPosition.region(region)) {
                            ForEach(nearbyParents) { parent in
                                if let coord = getParentCoordinates(parent) {
                                    Marker(parent.name, coordinate: coord)
                                        .tint(Color("AppPrimaryColor"))
                                }
                            }
                        }
                        .mapStyle(.standard)
                        .frame(height: 200)
                        .cornerRadius(12)
                    } else {
                        // Fallback for iOS 16 and earlier
                        // Create annotated items first
                        let annotatedItems = createAnnotatedItems()
                        Map(coordinateRegion: $region, annotationItems: annotatedItems) { item in
                            MapMarker(coordinate: item.coordinate, tint: Color("AppPrimaryColor"))
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                    }
                    
                    Text("Parents Near You")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(8)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal)
                
                // Upcoming events section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Upcoming Events")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: EventsView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(upcomingEvents) { event in
                                HomeEventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Nearby parents section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Connect with Parents")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            // View all nearby parents
                        }) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(nearbyParents) { parent in
                                ParentCard(parent: parent)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Spacer between sections
                Spacer()
                    .frame(height: 20)
                
                // Activities section
                VStack(alignment: .leading) {
                    HStack {
                        Text("Activities & Printables")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: ActivitiesView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(featuredActivities) { activity in
                                HomeActivityCard(activity: activity)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Parent Connect")
        .onAppear {
            loadMockData()
            
            // Update map with user's location if available
            if let userLocation = locationManager.location?.coordinate {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
    
    // Helper struct for Map annotations
    struct AnnotatedParent: Identifiable {
        let id: String
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
    
    // Helper function to pre-create annotated items
    private func createAnnotatedItems() -> [AnnotatedParent] {
        var items = [AnnotatedParent]()
        
        for parent in nearbyParents {
            if let coord = getParentCoordinates(parent) {
                items.append(AnnotatedParent(id: parent.id, name: parent.name, coordinate: coord))
            }
        }
        
        return items
    }
    
    // Helper function to get coordinates from a ParentPreview
    private func getParentCoordinates(_ parent: ParentPreview) -> CLLocationCoordinate2D? {
        // Mock implementation - in a real app, this would use actual stored coordinates
        let baseLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Generate a small random offset based on parent.id to differentiate the markers
        if let idNum = Int(parent.id) {
            let latOffset = Double(idNum % 10) * 0.002
            let longOffset = Double((idNum * 3) % 10) * 0.002
            return CLLocationCoordinate2D(
                latitude: baseLocation.latitude + latOffset,
                longitude: baseLocation.longitude + longOffset
            )
        }
        
        return baseLocation
    }
    
    private func loadMockData() {
        // Load mock data for nearby parents
        nearbyParents = [
            ParentPreview(id: "1", name: "Sarah Johnson", distance: "0.5 miles", childrenInfo: "2 kids (4, 6)"),
            ParentPreview(id: "2", name: "Mike Thompson", distance: "0.8 miles", childrenInfo: "1 kid (3)"),
            ParentPreview(id: "3", name: "Emma Roberts", distance: "1.2 miles", childrenInfo: "3 kids (2, 5, 7)")
        ]
        
        // Load mock data for upcoming events
        let currentDate = Date()
        let calendar = Calendar.current
        
        upcomingEvents = [
            EventPreview(id: "1", title: "Storytime at Library", date: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate, location: "Central Library"),
            EventPreview(id: "2", title: "Park Playdate", date: calendar.date(byAdding: .day, value: 2, to: currentDate) ?? currentDate, location: "Sunshine Park"),
            EventPreview(id: "3", title: "Kids Art Class", date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate, location: "Community Center")
        ]
        
        // Load mock data for featured activities
        featuredActivities = [
            ActivityPreview(id: "1", title: "Dinosaur Coloring Pages", type: "Printable"),
            ActivityPreview(id: "2", title: "Sensory Play Ideas", type: "Guide"),
            ActivityPreview(id: "3", title: "Letters Tracing Worksheet", type: "Printable")
        ]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Parent Card Component
struct ParentCard: View {
    let parent: ParentPreview
    
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 160)
                .overlay(
                    Text("👨‍👩‍👧‍👦")
                        .font(.system(size: 50))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(parent.name)
                    .font(.headline)
                
                Text(parent.childrenInfo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(parent.distance)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Handle connect action
                }) {
                    Text("Connect")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(20)
                }
                .padding(.top, 4)
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 160)
    }
}

struct HomeActivityCard: View {
    let activity: ActivityPreview
    
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .overlay(
                    Text("🎨")
                        .font(.system(size: 40))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(activity.type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AppPrimaryColor").opacity(0.2))
                    .foregroundColor(Color("AppPrimaryColor"))
                    .cornerRadius(4)
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 180)
    }
}

// Event Card for Home View
struct HomeEventCard: View {
    let event: EventPreview
    
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 100)
                .overlay(
                    Text("🎪")
                        .font(.system(size: 40))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formatDate(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(width: 200)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

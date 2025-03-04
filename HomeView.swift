import SwiftUI
import CoreData
import MapKit

struct HomeView: View {
    @State private var nearbyParents: [ParentPreview] = []
    @State private var upcomingEvents: [EventPreview] = []
    @State private var featuredActivities: [ActivityPreview] = []
    @State private var playdates: [Playdate] = []
    @State private var showingCreatePlaydateSheet = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Map section
                ZStack(alignment: .bottom) {
                    if #available(iOS 17.0, *) {
                        Map {
                            // You can add markers here when needed
                        }
                        .mapStyle(.standard)
                        .frame(height: 200)
                        .cornerRadius(12)
                    } else {
                        // Fallback for iOS 16 and earlier
                        Map(coordinateRegion: $region)
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
                
                // Nearby parents section
                VStack(alignment: .leading) {
                    Text("Connect with Parents")
                        .font(.title2)
                        .fontWeight(.bold)
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
                
                // Playdates section
                PlaydatesSection(playdates: $playdates, showingCreatePlaydateSheet: $showingCreatePlaydateSheet)
                
                // Upcoming events section
                VStack(alignment: .leading) {
                    Text("Upcoming Events")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(upcomingEvents) { event in
                                EventCard(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Activities section
                VStack(alignment: .leading) {
                    Text("Activities & Printables")
                        .font(.title2)
                        .fontWeight(.bold)
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
        }
        .sheet(isPresented: $showingCreatePlaydateSheet) {
            CreatePlaydateView(playdates: $playdates)
        }
    }
    
    private func loadMockData() {
        // Load mock data for nearby parents
        nearbyParents = [
            ParentPreview(id: "1", name: "Sarah Johnson", distance: "0.5 miles", childrenInfo: "2 kids (4, 6)"),
            ParentPreview(id: "2", name: "Mike Thompson", distance: "0.8 miles", childrenInfo: "1 kid (3)"),
            ParentPreview(id: "3", name: "Emma Roberts", distance: "1.2 miles", childrenInfo: "3 kids (2, 5, 7)")
        ]
        
        // Load mock data for upcoming events
        upcomingEvents = [
            EventPreview(id: "1", title: "Storytime at Library", date: Date().addingTimeInterval(86400), location: "Central Library"),
            EventPreview(id: "2", title: "Park Playdate", date: Date().addingTimeInterval(172800), location: "Sunshine Park"),
            EventPreview(id: "3", title: "Kids Art Class", date: Date().addingTimeInterval(259200), location: "Community Center")
        ]
        
        // Load mock data for featured activities
        featuredActivities = [
            ActivityPreview(id: "1", title: "Dinosaur Coloring Pages", type: "Printable"),
            ActivityPreview(id: "2", title: "Sensory Play Ideas", type: "Guide"),
            ActivityPreview(id: "3", title: "Letters Tracing Worksheet", type: "Printable")
        ]
        
        // Load mock playdates
        playdates = generateMockPlaydates()
    }
}

// Models
struct ParentPreview: Identifiable {
    let id: String
    let name: String
    let distance: String
    let childrenInfo: String
}

struct EventPreview: Identifiable {
    let id: String
    let title: String
    let date: Date
    let location: String
}

struct ActivityPreview: Identifiable {
    let id: String
    let title: String
    let type: String
}

// Component views
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

struct EventCard: View {
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

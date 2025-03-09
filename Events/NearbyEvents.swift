import SwiftUI
import MapKit
import CoreLocation

struct NearbyEvents: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var nearbyEvents: [EventPreview] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Finding events near you...")
            } else if nearbyEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "map.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(Color(.systemGray4))
                    
                    Text("No nearby events found")
                        .font(.headline)
                    
                    Text("Try expanding your search distance or check back later")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                List {
                    Section(header: Text("Events Near You")) {
                        ForEach(nearbyEvents) { event in
                            NavigationLink(destination: EventDetail(event: event)) {
                                EventDistanceRow(event: event, distance: distanceToEvent(event))
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Nearby Events")
        .onAppear {
            loadNearbyEvents()
        }
    }
    
    private func loadNearbyEvents() {
        isLoading = true
        
        // For demo, we'll just load all events and filter them by distance
        // In a real app, you would have location coordinates for each event
        // and filter in the database
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Create some mock events
        let events = [
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
            )
        ]
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Filter to nearby events only
            // In a real app, you would sort by actual distance
            self.nearbyEvents = events.filter { _ in
                // For demo purposes, we'll randomly include events
                return Bool.random()
            }
            self.isLoading = false
        }
    }
    
    // In a real app, you would calculate the actual distance
    // This is just a mock function that returns a random distance
    private func distanceToEvent(_ event: EventPreview) -> Double {
        // Generate a random distance between 0.1 and 9.9 miles
        return Double.random(in: 0.1...9.9)
    }
}

// Row that shows distance to event
struct EventDistanceRow: View {
    let event: EventPreview
    let distance: Double
    
    var body: some View {
        HStack(spacing: 15) {
            // Date component
            VStack(spacing: 2) {
                Text(formatDay(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatDayNumber(event.date))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color("AppPrimaryColor"))
                
                Text(formatMonth(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color("AppPrimaryColor").opacity(0.1))
            .cornerRadius(8)
            
            // Event info
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(event.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Distance info
                HStack {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f miles away", distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

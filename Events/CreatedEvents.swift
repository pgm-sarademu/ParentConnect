import SwiftUI
import CoreData

struct CreatedEvents: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var createdEvents: [EventPreview] = []
    @State private var isLoading = true
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: EventPreview?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading your events...")
            } else if createdEvents.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(Color(.systemGray4))
                    
                    Text("No created events")
                        .font(.headline)
                    
                    Text("Events you create will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: AddEventView()) {
                        Text("Create New Event")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(20)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                List {
                    ForEach(createdEvents) { event in
                        NavigationLink(destination: EventDetail(event: event)) {
                            CreatedEventRow(event: event)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                eventToDelete = event
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("My Created Events")
        .onAppear {
            loadCreatedEvents()
        }
        .alert("Delete Event?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let event = eventToDelete {
                    deleteEvent(event)
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
    
    private func loadCreatedEvents() {
        isLoading = true
        
        // In a real app, you would fetch from Core Data with a predicate for current user ID
        // For demo, we'll use mock data
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.createdEvents = [
                EventPreview(
                    id: "101",
                    title: "Playground Meetup",
                    date: calendar.date(byAdding: .day, value: 3, to: currentDate) ?? currentDate,
                    location: "Central Park Playground"
                ),
                EventPreview(
                    id: "102",
                    title: "Kids Book Club",
                    date: calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate,
                    location: "City Library"
                ),
                EventPreview(
                    id: "103",
                    title: "Parent Coffee Morning",
                    date: calendar.date(byAdding: .day, value: 10, to: currentDate) ?? currentDate,
                    location: "Sunshine Café"
                )
            ]
            
            self.isLoading = false
        }
    }
    
    private func deleteEvent(_ event: EventPreview) {
        // Remove from local array first for immediate UI update
        createdEvents.removeAll { $0.id == event.id }
        
        // In a real app, you would:
        // 1. Delete from Core Data
        // 2. Sync with server if needed
    }
}

struct CreatedEventRow: View {
    let event: EventPreview
    
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
            }
            
            Spacer()
            
            // Status indicator
            VStack {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(10)
            }
        }
    }
    
    // Add date formatting functions here
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
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

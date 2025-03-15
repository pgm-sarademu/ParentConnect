import SwiftUI
import CoreData

struct CreatedEvents: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var createdEvents: [EventPreview] = []
    @State private var isLoading = true
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: EventPreview?
    @State private var searchText = ""

    
    var filteredEvents: [EventPreview] {
        if searchText.isEmpty {
            return createdEvents
        } else {
            return createdEvents.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom title without profile button
            HStack {
                Text("Created Events")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 15)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search created events", text: $searchText)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            if isLoading {
                Spacer()
                ProgressView("Loading your events...")
                Spacer()
            } else if filteredEvents.isEmpty {
                Spacer()
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
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Event")
                        }
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
                Spacer()
            } else {
                // Grid layout for events
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 15)], spacing: 15) {
                        ForEach(filteredEvents) { event in
                            NavigationLink {
                                EventDetail(event: event)
                            } label: {
                                EventCardView(event: event)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            eventToDelete = event
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
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

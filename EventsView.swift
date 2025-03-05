import SwiftUI
import CoreData
import MapKit

struct EventsView: View {
    @State private var events: [EventPreview] = []
    @State private var searchText = ""
    @State private var selectedFilter: String? = "All"
    @State private var showingAddEventSheet = false
    
    let filters = ["All", "Today", "This Week", "Kid-Friendly", "Free"]
    
    var filteredEvents: [EventPreview] {
        var filtered = events
        
        if let filter = selectedFilter, filter != "All" {
            switch filter {
            case "Today":
                let today = Calendar.current.startOfDay(for: Date())
                filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            case "This Week":
                let today = Calendar.current.startOfDay(for: Date())
                guard let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: today) else {
                    return filtered
                }
                filtered = filtered.filter { $0.date >= today && $0.date <= oneWeekLater }
            // Add other filters as needed
            default:
                break
            }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedFilter == filter ?
                                        Color("AppPrimaryColor") :
                                        Color(.systemGray6)
                                    )
                                    .foregroundColor(
                                        selectedFilter == filter ?
                                        .white :
                                        .primary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
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
                        
                        Text("Try changing your filters or check back later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            selectedFilter = "All"
                            searchText = ""
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
                    List {
                        ForEach(filteredEvents) { event in
                            NavigationLink(destination: EnhancedEventDetailView(event: event)) {
                                EventListRow(event: event)
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
                EventForm()
            }
        }
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
            )
        ]
    }
}

struct EventListRow: View {
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

struct EventDetailView: View {
    let event: EventPreview
    @State private var isAttending = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event image/banner
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    Text("🎪")
                        .font(.system(size: 80))
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Title and date
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatFullDate(event.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatTime(event.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(event.location)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Event details
                    Text("Event Details")
                        .font(.headline)
                    
                    Text("Join us for a fantastic event suitable for children of all ages. This event promises fun activities, learning opportunities, and a chance to connect with other families in your community.")
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
                    
                    Divider()
                    
                    // Map preview
                    Text("Location")
                        .font(.headline)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .cornerRadius(12)
                        
                        Text("📍 \(event.location)")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    // Organizer info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Organized by")
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
                                Text("Community Events Team")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("events@community.org")
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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

import SwiftUI

struct EventCard: View {
    let event: EventPreview
    
    // In a real app, these would be calculated from your data model
    let hasActiveChat: Bool = Bool.random() // Randomly show chat indicator in preview
    let chatParticipantCount: Int = Int.random(in: 2...15)
    let unreadChatMessages: Int = Int.random(in: 0...5)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event image with date overlay
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay(
                        Text("🎪")
                            .font(.system(size: 40))
                    )
                
                // Date badge overlay
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text(formatDay(event.date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(formatDayNumber(event.date))
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
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(formatTime(event.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(event.location)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Age recommendation - simulated based on ID for demo
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    // Generate a simulated age range based on event ID
                    let minAge = (Int(event.id) ?? 0) % 15 + 1
                    Text("Ages \(minAge)-\(minAge+3)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Chat information row
                if hasActiveChat {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("\(chatParticipantCount) in chat")
                            .font(.system(size: 12))
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        if unreadChatMessages > 0 {
                            Text("• \(unreadChatMessages) new")
                                .font(.system(size: 12))
                                .foregroundColor(Color("AppPrimaryColor"))
                                .fontWeight(.medium)
                        }
                    }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Modified Events view to use the EventCard
struct Events: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var events: [EventPreview] = []
    @State private var searchText = ""
    @State private var showingAddEventSheet = false
    @State private var showingFilters = false
    @State private var filters = EventFilters()
    @State private var showingProfileView = false
    
    // Mock user data for ordering by age relevance
    @State private var userChildAges = [4, 6]  // Would come from user profile in a real app
    
    var filteredEvents: [EventPreview] {
        var filtered = events
        
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
            break // All events
        }
        
        // Apply other filters as in your original code
        
        // Sort by date, location proximity, and child age relevance
        return dateBasedSort(filtered)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom title with profile button
                HStack {
                    Text("Events")
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
                        TextField("Search events", text: $searchText)
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
                    
                    // Add Event button (just + icon)
                    Button(action: {
                        showingAddEventSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    .padding(.leading, 8)
                }
                .padding()
                
                // Active filter tags and other UI elements as in your original code
                
                // Event Grid Layout
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 15)], spacing: 15) {
                        ForEach(filteredEvents) { event in
                            NavigationLink {
                                EventDetail(event: event)
                            } label: {
                                EventCard(event: event)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
            .onAppear {
                loadMockEvents()
                loadUserProfile()
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .sheet(isPresented: $showingFilters) {
                EventFiltersView(filters: $filters, isPresented: $showingFilters)
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
            }
        }
    }
    
    // Your existing methods for loading events, sorting, etc.
    private func loadUserProfile() {
        // In a real app, this would come from Core Data or user preferences
        userChildAges = [4, 6]
    }
    
    // Date-based sorting (simplified)
    private func dateBasedSort(_ events: [EventPreview]) -> [EventPreview] {
        events.sorted { e1, e2 in
            let days1 = daysBetween(Date(), e1.date)
            let days2 = daysBetween(Date(), e2.date)
            
            // Events happening sooner come first
            return days1 < days2
        }
    }
    
    // Calculate days between two dates
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: start, to: end)
        return components.day ?? 0
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
            // More events as in your original code
        ]
    }
}

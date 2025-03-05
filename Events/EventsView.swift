import SwiftUI
import CoreData
import MapKit

struct EventsView: View {
    @State private var events: [EventPreview] = []
    @State private var searchText = ""
    @State private var showingAddEventSheet = false
    @State private var showingFilters = false
    @State private var filters = EventFilters()
    
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
        
        // Apply price filter - in real app, would need to check Event entity's isPaid field
        switch filters.priceFilter {
        case .free:
            // For demo, we're just checking even/odd IDs to simulate free/paid events
            filtered = filtered.filter {
                let idNumber = Int($0.id) ?? 0
                return idNumber % 2 == 0 // Even IDs are "free" for demo
            }
        case .paid:
            // For demo, we're just checking even/odd IDs to simulate free/paid events
            filtered = filtered.filter {
                let idNumber = Int($0.id) ?? 0
                return idNumber % 2 != 0 // Odd IDs are "paid" for demo
            }
        default:
            break // All events
        }
        
        // Apply age filter - in real app, we would check the Event entity's ageRange property
        if filters.ageFilter != "All Ages" {
            // This is just a simulation filter - in a real app we would parse the age range properly
            filtered = filtered.filter { event in
                // For demo, filter based on ID length to simulate different age ranges
                let idLength = event.id.count
                
                switch filters.ageFilter {
                case "0-2 years":
                    return idLength == 1
                case "3-5 years":
                    return idLength == 2
                case "6-8 years":
                    return idLength == 3
                case "9-12 years":
                    return idLength == 4
                case "Teenagers":
                    return idLength >= 5
                default:
                    return true
                }
            }
        }
        
        // Apply distance filter
        if filters.distanceFilter != .any {
            // In a real app, you would calculate actual distances
            // For demo, we'll use ID value to simulate
            filtered = filtered.filter { event in
                let idValue = Int(event.id) ?? 0
                let mockDistance = Double(idValue) * 0.5 // Mock distance in miles
                return mockDistance <= filters.distanceFilter.distance
            }
        }
        
        return filtered.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter summary bar
                HStack(spacing: 12) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                            Text("Filters")
                                .font(.system(size: 15, weight: .medium))
                            
                            // Shows active filter count
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 22, height: 22)
                                    .background(Color("AppPrimaryColor"))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    
                    // Active filter tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if filters.priceFilter != .all {
                                FilterTag(text: filters.priceFilter.rawValue) {
                                    filters.priceFilter = .all
                                }
                            }
                            
                            if filters.ageFilter != "All Ages" {
                                FilterTag(text: filters.ageFilter) {
                                    filters.ageFilter = "All Ages"
                                }
                            }
                            
                            if filters.selectedDateRange != .all {
                                FilterTag(text: filters.selectedDateRange.rawValue) {
                                    filters.selectedDateRange = .all
                                }
                            }
                            
                            if filters.distanceFilter != .any {
                                FilterTag(text: filters.distanceFilter.rawValue) {
                                    filters.distanceFilter = .any
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if activeFilterCount > 0 {
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
                
                // Add nearby events button
                VStack {
                    Divider()
                        .padding(.vertical, 8)
                    
                    NavigationLink(destination: NearbyEventsView()) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Find Events Near Me")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("AppPrimaryColor").opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
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
                AddEventView()
            }
            .sheet(isPresented: $showingFilters) {
                EventFiltersView(filters: $filters, isPresented: $showingFilters)
            }
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if filters.priceFilter != .all { count += 1 }
        if filters.ageFilter != "All Ages" { count += 1 }
        if filters.selectedDateRange != .all { count += 1 }
        if filters.distanceFilter != .any { count += 1 }
        return count
    }
    
    private func resetFilters() {
        filters = EventFilters()
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

// Event List Row Component - Include it in this file to fix the "Cannot find 'EventListRow' in scope" error
struct EventListRow: View {
    let event: EventPreview
    
    var body: some View {
        HStack(spacing: 15) {
            // Date component
            VStack(spacing: 2) {
                Text(formatDay(event.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(formatDayNumber(event.date))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color("AppPrimaryColor"))
                
                Text(formatMonth(event.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AppPrimaryColor").opacity(0.1))
            )
            
            // Event info
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(formatTime(event.date))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(event.location)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
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

import SwiftUI

struct EventFilters {
    var priceFilter: PriceFilter = .all
    var ageFilter: String = "All Ages"
    var selectedDateRange: DateRangeFilter = .all
    var distanceFilter: DistanceFilter = .any
    
    enum PriceFilter: String, CaseIterable {
        case all = "All"
        case free = "Free"
        case paid = "Paid"
    }
    
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
}

// Modern, stylish filter chip UI
struct FilterChip: View {
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

// Price filter chip with icon
struct PriceFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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

// Active filter tag component for displaying selected filters
struct FilterTag: View {
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

struct EventFiltersView: View {
    @Binding var filters: EventFilters
    @Binding var isPresented: Bool
    @State private var tempFilters: EventFilters
    
    // Common age ranges for kids' activities
    let ageRanges = ["All Ages", "0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers"]
    
    init(filters: Binding<EventFilters>, isPresented: Binding<Bool>) {
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
                            ForEach(EventFilters.DateRangeFilter.allCases, id: \.self) { option in
                                FilterChip(
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
                
                // Price filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Price")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(EventFilters.PriceFilter.allCases, id: \.self) { option in
                                FilterChip(
                                    title: option.rawValue,
                                    isSelected: tempFilters.priceFilter == option,
                                    action: {
                                        tempFilters.priceFilter = option
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
                
                // Age range filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Age Range")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ageRanges, id: \.self) { range in
                                FilterChip(
                                    title: range,
                                    isSelected: tempFilters.ageFilter == range,
                                    action: {
                                        tempFilters.ageFilter = range
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
                
                // Distance filter section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Distance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(EventFilters.DistanceFilter.allCases, id: \.self) { option in
                                FilterChip(
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
                        Text("\(activeFilterCount) filters applied")
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
                            tempFilters = EventFilters()
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
            .navigationTitle("Filter Events")
            .navigationBarItems(
                trailing: Button("Close") {
                    isPresented = false
                }
            )
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }
    
    // Count active filters
    private var activeFilterCount: Int {
        var count = 0
        if tempFilters.priceFilter != .all { count += 1 }
        if tempFilters.ageFilter != "All Ages" { count += 1 }
        if tempFilters.selectedDateRange != .all { count += 1 }
        if tempFilters.distanceFilter != .any { count += 1 }
        return count
    }
    
    // Helper function to get the appropriate icon for each price filter option
    private func priceIcon(for option: EventFilters.PriceFilter) -> String {
        switch option {
        case .all:
            return "tag"
        case .free:
            return "gift"
        case .paid:
            return "dollarsign.circle"
        }
    }
}

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
            Form {
                Section(header: Text("Price")) {
                    Picker("Price", selection: $tempFilters.priceFilter) {
                        ForEach(EventFilters.PriceFilter.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                
                Section(header: Text("Location")) {
                    Picker("Distance", selection: $tempFilters.distanceFilter) {
                        ForEach(EventFilters.DistanceFilter.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                // Clear all filters button
                Section {
                    Button(action: {
                        // Reset all filters to default values
                        tempFilters = EventFilters()
                    }) {
                        HStack {
                            Spacer()
                            Text("Remove All Filters")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Age Range")) {
                    Picker("Age Range", selection: $tempFilters.ageFilter) {
                        ForEach(ageRanges, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section(header: Text("Date")) {
                    Picker("Time Period", selection: $tempFilters.selectedDateRange) {
                        ForEach(EventFilters.DateRangeFilter.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Filter Events")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Apply") {
                    filters = tempFilters
                    isPresented = false
                }
                .fontWeight(.bold)
            )
        }
    }
}

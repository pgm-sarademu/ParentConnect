import SwiftUI

struct EventFilters {
    var priceFilter: PriceFilter = .all
    var ageFilter: String = "All Ages"
    var selectedDateRange: DateRangeFilter = .all
    
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

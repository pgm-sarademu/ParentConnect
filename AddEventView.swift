import SwiftUI
import MapKit

struct AddEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date()
    @State private var eventLocation = ""
    @State private var isPaidEvent = false
    @State private var eventPrice: String = ""
    @State private var eventCapacity: String = ""
    @State private var selectedAgeRange = "All Ages"
    @State private var showingLocationPicker = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingSuccessAlert = false
    
    let ageRanges = ["All Ages", "0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers", "Adults Only"]
    
    var formIsValid: Bool {
        !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !eventLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (!isPaidEvent || (isPaidEvent && !eventPrice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $eventTitle)
                    
                    DatePicker("Date & Time", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Location", text: $eventLocation)
                        .onTapGesture {
                            showingLocationPicker = true
                        }
                }
                
                Section(header: Text("Event Description")) {
                    TextEditor(text: $eventDescription)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Age Range")) {
                    Picker("Suitable for", selection: $selectedAgeRange) {
                        ForEach(ageRanges, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Event Type")) {
                    Toggle("This is a paid event", isOn: $isPaidEvent)
                    
                    if isPaidEvent {
                        HStack {
                            Text("$")
                            TextField("Price", text: $eventPrice)
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    HStack {
                        Text("Capacity")
                        TextField("Optional", text: $eventCapacity)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    Button(action: saveEvent) {
                        Text("Create Event")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(formIsValid ? Color("AppPrimaryColor") : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!formIsValid)
                }
            }
            .navigationTitle("Add New Event")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $eventLocation, selectedCoordinate: $selectedCoordinate)
            }
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Event Created"),
                    message: Text("Your event has been successfully created."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func saveEvent() {
        // Create a new Event entity
        let newEvent = Event(context: viewContext)
        newEvent.id = UUID().uuidString
        newEvent.title = eventTitle
        newEvent.eventDescription = eventDescription
        newEvent.date = eventDate
        newEvent.location = eventLocation
        newEvent.isPaid = isPaidEvent
        
        if isPaidEvent, let priceValue = Decimal(string: eventPrice) {
            newEvent.price = NSDecimalNumber(decimal: priceValue)
        }
        
        if let capacityValue = Int32(eventCapacity) {
            newEvent.capacity = capacityValue
            newEvent.spotsRemaining = capacityValue
        }
        
        newEvent.ageRange = selectedAgeRange
        newEvent.createdBy = "current_user_id" // In a real app, this would be the current user's ID
        
        if let coordinate = selectedCoordinate {
            newEvent.latitude = coordinate.latitude
            newEvent.longitude = coordinate.longitude
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            showingSuccessAlert = true
        } catch {
            // Handle the error
            print("Error saving event: \(error)")
        }
    }
    
    private func privacyIcon(for level: String) -> String {
        switch level {
        case "Private":
            return "lock.fill"
        case "Friends":
            return "person.2.fill"
        case "Selected":
            return "person.crop.circle.badge.checkmark"
        case "Public":
            return "globe"
        default:
            return "globe"
        }
    }
}

// Privacy level for events
enum PrivacyLevel: String, CaseIterable {
    case private
    case friends
    case selected
    case public
    
    var description: String {
        switch self {
        case .private:
            return "Only Me"
        case .friends:
            return "Friends Only"
        case .selected:
            return "Selected Friends"
        case .public:
            return "Public"
        }
    }
}

// View to select location on map
struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var searchText = ""
    @State private var locationName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search for a location", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                    .onChange(of: searchText) { _ in
                        searchLocation()
                    }
                
                // Map
                if #available(iOS 17.0, *) {
                    Map(initialPosition: MapCameraPosition.region(region)) {
                        if let coordinate = selectedCoordinate {
                            Marker("Selected Location", coordinate: coordinate)
                                .tint(Color("AppPrimaryColor"))
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture { location in
                        let locationCoordinate = location
                        selectedCoordinate = locationCoordinate
                        getLocationName(for: locationCoordinate)
                    }
                } else {
                    // Fallback for iOS 16 and earlier
                    Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: nil, annotationItems: selectedCoordinate.map { [AnnotatedLocation(coordinate: $0)] } ?? []) { item in
                        MapMarker(coordinate: item.coordinate, tint: Color("AppPrimaryColor"))
                    }
                    .onTapGesture { location in
                        // This is a simplified approximation since direct tap coordinates aren't available in older iOS
                        let tapPoint = CGPoint(x: location.x, y: location.y)
                        let tapCoordinate = mapPoint(for: tapPoint)
                        selectedCoordinate = tapCoordinate
                        getLocationName(for: tapCoordinate)
                    }
                }
                
                // Selected location display
                if !locationName.isEmpty {
                    HStack {
                        Text("Selected: \(locationName)")
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Confirm button
                Button(action: {
                    selectedLocation = locationName
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Confirm Location")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(locationName.isEmpty ? Color.gray : Color("AppPrimaryColor"))
                        .cornerRadius(10)
                        .padding()
                }
                .disabled(locationName.isEmpty)
            }
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func searchLocation() {
        // This would use MapKit to search for the location
        // For simplicity, we're not implementing the full search functionality
    }
    
    private func getLocationName(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let name = placemark.name ?? ""
                let thoroughfare = placemark.thoroughfare ?? ""
                let locality = placemark.locality ?? ""
                
                if !name.isEmpty {
                    locationName = name
                } else if !thoroughfare.isEmpty {
                    locationName = thoroughfare + (!locality.isEmpty ? ", \(locality)" : "")
                } else {
                    locationName = "Selected Location"
                }
            }
        }
    }
    
    // Helper function for older iOS versions to approximate tap location
    private func mapPoint(for tapPoint: CGPoint) -> CLLocationCoordinate2D {
        // This is a simplified approximation
        // In a real app, you would use MKMapView's convert method
        return region.center
    }
    
    // Helper struct for map annotations
    struct AnnotatedLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
    }
}

// View to select friends for event visibility
struct SelectFriendsView: View {
    @State private var friends: [FriendModel] = []
    @State private var selectedFriends: Set<String> = []
    
    var body: some View {
        List(friends) { friend in
            HStack {
                Text(friend.name)
                Spacer()
                Image(systemName: selectedFriends.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedFriends.contains(friend.id) ? Color("AppPrimaryColor") : .gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedFriends.contains(friend.id) {
                    selectedFriends.remove(friend.id)
                } else {
                    selectedFriends.insert(friend.id)
                }
            }
        }
        .navigationTitle("Select Friends")
        .onAppear {
            loadMockFriends()
        }
    }
    
    private func loadMockFriends() {
        friends = [
            FriendModel(id: "1", name: "Sarah Johnson"),
            FriendModel(id: "2", name: "Mike Thompson"),
            FriendModel(id: "3", name: "Emma Roberts"),
            FriendModel(id: "4", name: "David Wilson"),
            FriendModel(id: "5", name: "Jessica Brown")
        ]
    }
    
    struct FriendModel: Identifiable {
        let id: String
        let name: String
    }
}

struct AddEventView_Previews: PreviewProvider {
    static var previews: some View {
        AddEventView()
    }
}

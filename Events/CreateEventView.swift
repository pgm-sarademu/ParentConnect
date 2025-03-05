import SwiftUI
import CoreData
import MapKit

struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var locationManager: LocationManager
    
    // Form fields
    @State private var title = ""
    @State private var eventDescription = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var isPaid = false
    @State private var price: Double = 0.0
    @State private var capacity: Int = 10
    @State private var ageRange = "All Ages"
    @State private var visibilityLevel = "Friends Only"
    
    // UI states
    @State private var showingLocationPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedCoordinate = CLLocationCoordinate2D()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Pickers data
    let ageRanges = ["All Ages", "0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers"]
    let visibilityOptions = ["Public", "Friends Only", "Invite Only", "Private"]
    
    var body: some View {
        NavigationView {
            Form {
                // Event basic info
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    
                    DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Location", text: $location)
                        .onTapGesture {
                            showingLocationPicker = true
                        }
                    
                    // Location selection button
                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(Color("AppPrimaryColor"))
                            Text("Set Location on Map")
                        }
                    }
                }
                
                // Event description
                Section(header: Text("Description")) {
                    TextEditor(text: $eventDescription)
                        .frame(height: 100)
                }
                
                // Event options
                Section(header: Text("Options")) {
                    Picker("Age Range", selection: $ageRange) {
                        ForEach(ageRanges, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...100)
                    
                    Toggle("This is a paid event", isOn: $isPaid)
                    
                    if isPaid {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $price, format: .number)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                // Privacy settings
                Section(header: Text("Privacy & Visibility")) {
                    Picker("Who can see this event?", selection: $visibilityLevel) {
                        ForEach(visibilityOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if visibilityLevel == "Invite Only" {
                        NavigationLink(destination: InviteFriendsView()) {
                            Text("Select friends to invite")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Privacy Levels:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Public: Visible to all ParentConnect users")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Friends Only: Visible to your confirmed friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Invite Only: Only visible to people you specifically invite")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Private: Only visible to you")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                
                // Submit button
                Section {
                    Button(action: createEvent) {
                        Text("Create Event")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(10)
                    }
                    .disabled(title.isEmpty || location.isEmpty)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: $location, selectedCoordinate: $selectedCoordinate, region: $region)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Create Event"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .onAppear {
                if let userLocation = locationManager.location?.coordinate {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                }
            }
        }
    }
    
    // Save event to Core Data
    private func createEvent() {
        guard !title.isEmpty, !location.isEmpty else {
            alertMessage = "Please fill in all required fields (title and location)"
            showingAlert = true
            return
        }
        
        // Create a new Event entity
        let newEvent = Event(context: viewContext)
        newEvent.id = UUID().uuidString
        newEvent.title = title
        newEvent.eventDescription = eventDescription
        newEvent.location = location
        newEvent.date = date
        newEvent.isPaid = isPaid ? date : nil // Using date as a boolean flag since Core Data doesn't have boolean
        newEvent.price = NSDecimalNumber(value: isPaid ? price : 0.0)
        newEvent.capacity = Int32(capacity)
        newEvent.spotsRemaining = Int32(capacity)
        newEvent.ageRange = ageRange
        
        // Set coordinates if available
        if CLLocationCoordinate2D.isValidCoordinate(selectedCoordinate) {
            newEvent.latitude = selectedCoordinate.latitude
            newEvent.longitude = selectedCoordinate.longitude
        }
        
        // Set the creator
        // In a real app, you would use the current user's ID
        newEvent.createdBy = "currentUserId"
        
        // Handle privacy based on visibilityLevel
        // You would implement actual visibility logic in your queries
        
        do {
            try viewContext.save()
            alertMessage = "Event created successfully!"
            showingAlert = true
            
            // If it's an invite-only event, you would create invites here
            if visibilityLevel == "Invite Only" {
                // Code to create invites would go here
                // This would use the EventParticipant entity
            }
        } catch {
            alertMessage = "Could not save event: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Helper view for picking location on a map
struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: String
    @Binding var selectedCoordinate: CLLocationCoordinate2D
    @Binding var region: MKCoordinateRegion
    
    @State private var tempCoordinate: CLLocationCoordinate2D?
    @State private var addressText = "Tap the map to select a location"
    
    var body: some View {
        NavigationView {
            ZStack {
                if #available(iOS 17.0, *) {
                    Map(initialPosition: MapCameraPosition.region(region), interactionModes: .all) {
                        if let coordinate = tempCoordinate {
                            Marker("Selected Location", coordinate: coordinate)
                                .tint(.red)
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture { position in
                        if let coordinate = position.coordinate {
                            tempCoordinate = coordinate
                            getAddressFromCoordinate(coordinate)
                        }
                    }
                } else {
                    // Fallback for iOS 16 and earlier
                    MapWithTap(region: $region, selectedCoordinate: $tempCoordinate, onLocationSelected: { coordinate in
                        getAddressFromCoordinate(coordinate)
                    })
                }
                
                VStack {
                    Spacer()
                    
                    // Address display
                    Text(addressText)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        .padding()
                }
            }
            .navigationTitle("Select Location")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Confirm") {
                    if let coordinate = tempCoordinate {
                        selectedCoordinate = coordinate
                        if addressText != "Tap the map to select a location" {
                            selectedLocation = addressText
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(tempCoordinate == nil)
            )
        }
    }
    
    private func getAddressFromCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                addressText = "Location selected"
                return
            }
            
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let name = placemark.name, !name.isEmpty {
                    addressComponents.append(name)
                }
                
                if let thoroughfare = placemark.thoroughfare, !thoroughfare.isEmpty {
                    addressComponents.append(thoroughfare)
                }
                
                if let locality = placemark.locality, !locality.isEmpty {
                    addressComponents.append(locality)
                }
                
                if let administrativeArea = placemark.administrativeArea, !administrativeArea.isEmpty {
                    addressComponents.append(administrativeArea)
                }
                
                addressText = addressComponents.joined(separator: ", ")
                if addressText.isEmpty {
                    addressText = "Location selected"
                }
            } else {
                addressText = "Location selected"
            }
        }
    }
}

// For iOS 16 and earlier
struct MapWithTap: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    var onLocationSelected: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        
        // Clear existing annotations
        uiView.removeAnnotations(uiView.annotations)
        
        // Add annotation for selected coordinate
        if let coordinate = selectedCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Selected Location"
            uiView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapWithTap
        
        init(_ parent: MapWithTap) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            parent.selectedCoordinate = coordinate
            parent.onLocationSelected(coordinate)
        }
    }
}

// Simple view for inviting friends
struct InviteFriendsView: View {
    @State private var friends = [
        ("Sarah Johnson", false),
        ("Mike Thompson", false),
        ("Emma Roberts", false),
        ("David Wilson", false),
        ("Olivia Garcia", false)
    ]
    
    var body: some View {
        List {
            ForEach(0..<friends.count, id: \.self) { index in
                Button(action: {
                    friends[index].1.toggle()
                }) {
                    HStack {
                        Text(friends[index].0)
                        Spacer()
                        if friends[index].1 {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Invite Friends")
    }
}

// Helper extension to check if coordinates are valid
extension CLLocationCoordinate2D {
    static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return coordinate.latitude != 0 && coordinate.longitude != 0
    }
}

import SwiftUI
import CoreData

struct AddEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form fields
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var isPaid = false
    @State private var price: String = ""
    @State private var ageRange = ""
    @State private var privacyOption = 0 // 0=Public, 1=Friends, 2=Private
    
    // Participant limits
    @State private var hasParticipantLimit = false
    @State private var maxChildrenCount = 10
    @State private var limitDescription = ""
    
    // Error handling
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("Date & Time", selection: $date)
                    TextField("Age Range (e.g., 3-5 years)", text: $ageRange)
                        .keyboardType(.default)
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Privacy")) {
                    Picker("Who can see this event?", selection: $privacyOption) {
                        Text("Public").tag(0)
                        Text("Friends Only").tag(1)
                        Text("Private (Invite Only)").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Participant Limits")) {
                    Toggle("Limit number of participants", isOn: $hasParticipantLimit)
                    
                    if hasParticipantLimit {
                        Stepper("Maximum number of children: \(maxChildrenCount)", value: $maxChildrenCount, in: 1...100)
                        
                        Text("This will limit the event to a maximum of \(maxChildrenCount) children total, regardless of how many parents attend.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Additional limit notes (optional)", text: $limitDescription)
                            .font(.subheadline)
                    }
                }
                
                Section(header: Text("Pricing")) {
                    Toggle("This is a paid event", isOn: $isPaid)
                    
                    if isPaid {
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Button(action: saveEvent) {
                    Text("Create Event")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveEvent() {
        // Basic validation
        guard !title.isEmpty else {
            alertMessage = "Please enter a title"
            showingAlert = true
            return
        }
        
        guard !location.isEmpty else {
            alertMessage = "Please enter a location"
            showingAlert = true
            return
        }
        
        if isPaid && price.isEmpty {
            alertMessage = "Please enter a price"
            showingAlert = true
            return
        }
        
        // Create the event in Core Data
        let newEvent = Event(context: viewContext)
        newEvent.id = UUID().uuidString
        newEvent.title = title
        newEvent.location = location
        newEvent.eventDescription = description
        newEvent.date = date
        newEvent.ageRange = ageRange
        
        // Add participant limits
        if hasParticipantLimit {
            newEvent.capacity = Int32(maxChildrenCount)
            newEvent.spotsRemaining = Int32(maxChildrenCount)
        } else {
            // Use -1 to indicate no limit
            newEvent.capacity = -1
            newEvent.spotsRemaining = -1
        }
        
        // Handle pricing
        if isPaid {
            newEvent.isPaid = date // Using as a boolean placeholder since we already have this field
            if let priceValue = Decimal(string: price) {
                newEvent.price = NSDecimalNumber(decimal: priceValue)
            }
        }
        
        // Store the privacy option in UserDefaults since we don't have a field for it
        let privacySettings = UserDefaults.standard.dictionary(forKey: "EventPrivacySettings") as? [String: Int] ?? [:]
        var updatedSettings = privacySettings
        updatedSettings[newEvent.id!] = privacyOption
        UserDefaults.standard.set(updatedSettings, forKey: "EventPrivacySettings")
        
        // Store participant limit description if available
        if hasParticipantLimit && !limitDescription.isEmpty {
            let limitDescriptions = UserDefaults.standard.dictionary(forKey: "EventLimitDescriptions") as? [String: String] ?? [:]
            var updatedLimitDescriptions = limitDescriptions
            updatedLimitDescriptions[newEvent.id!] = limitDescription
            UserDefaults.standard.set(updatedLimitDescriptions, forKey: "EventLimitDescriptions")
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Could not save event: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

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
    @State private var organizerName = ""
    
    // Participant limits
    @State private var hasParticipantLimit = false
    @State private var maxChildrenCount = 10
    @State private var limitDescription = ""
    
    // Recurring event settings
    @State private var isRecurring = false
    @State private var recurrenceType = 0 // 0=Daily, 1=Weekly, 2=Monthly
    @State private var recurrenceEndDate = Date().addingTimeInterval(30 * 24 * 3600) // 30 days from now
    @State private var recurrenceFrequency = 1 // every X days/weeks/months
    
    // Error handling
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Event Details
                Section {
                    TextField("Event Title", text: $title)
                        .font(.body)
                    
                    TextField("Location", text: $location)
                        .font(.body)
                    
                    DatePicker("Date & Time", selection: $date)
                        .font(.body)
                    
                    TextField("Age Range (e.g., 3-5 years)", text: $ageRange)
                        .font(.body)
                        .keyboardType(.default)
                    
                    TextField("Organizer/Host", text: $organizerName)
                        .font(.body)
                } header: {
                    Text("Event Details")
                }
                
                // MARK: - Description
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .font(.body)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe your event...")
                                        .foregroundColor(.gray)
                                        .font(.body)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                } header: {
                    Text("Description")
                }
                
                // MARK: - Recurring Event Options
                Section {
                    Toggle("This is a recurring event", isOn: $isRecurring.animation())
                    
                    if isRecurring {
                        // Repeat frequency
                        Picker("Repeats", selection: $recurrenceType) {
                            Text("Daily").tag(0)
                            Text("Weekly").tag(1)
                            Text("Monthly").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Repeat every X days/weeks/months
                        HStack {
                            Text("Repeat every")
                            Spacer()
                            
                            Picker("", selection: $recurrenceFrequency) {
                                ForEach(1...30, id: \.self) { number in
                                    Text("\(number)").tag(number)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 60)
                            
                            Text(recurrenceTypeName(type: recurrenceType, frequency: recurrenceFrequency))
                                .foregroundColor(.gray)
                        }
                        
                        // End date
                        DatePicker("Ends on", selection: $recurrenceEndDate, in: date...)
                            .datePickerStyle(DefaultDatePickerStyle())
                        
                        // Preview of occurrences
                        if !calculateOccurrences().isEmpty {
                            HStack {
                                Text("Next occurrence:")
                                    .font(.footnote)
                                Spacer()
                                Text(formatDate(calculateOccurrences()[0]))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Recurring Event")
                }
                
                // MARK: - Privacy
                Section {
                    Picker("Privacy", selection: $privacyOption) {
                        Text("Public").tag(0)
                        Text("Friends Only").tag(1)
                        Text("Private (Invite Only)").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Privacy")
                }
                
                // MARK: - Participant Limits
                Section {
                    Toggle("Limit number of participants", isOn: $hasParticipantLimit.animation())
                    
                    if hasParticipantLimit {
                        Stepper("\(maxChildrenCount) children maximum", value: $maxChildrenCount, in: 1...100)
                        
                        TextField("Additional limit notes", text: $limitDescription)
                            .font(.body)
                    }
                } header: {
                    Text("Participant Limits")
                }
                
                // MARK: - Pricing
                Section {
                    Toggle("This is a paid event", isOn: $isPaid.animation())
                    
                    if isPaid {
                        HStack {
                            Text("$")
                            TextField("Price", text: $price)
                                .keyboardType(.decimalPad)
                        }
                    }
                } header: {
                    Text("Pricing")
                }
                
                // MARK: - Create Button
                Section {
                    Button(action: saveEvent) {
                        Text("Create Event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color("AppPrimaryColor"))
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func recurrenceTypeName(type: Int, frequency: Int) -> String {
        let plural = frequency > 1
        
        switch type {
        case 0:
            return plural ? "days" : "day"
        case 1:
            return plural ? "weeks" : "week"
        case 2:
            return plural ? "months" : "month"
        default:
            return ""
        }
    }
    
    private func calculateOccurrences() -> [Date] {
        var occurrences: [Date] = []
        
        // First occurrence is the original date
        occurrences.append(date)
        
        var intervalInSeconds: TimeInterval = 0
        switch recurrenceType {
        case 0: // Daily
            intervalInSeconds = Double(recurrenceFrequency) * 24 * 3600
        case 1: // Weekly
            intervalInSeconds = Double(recurrenceFrequency) * 7 * 24 * 3600
        case 2: // Monthly
            intervalInSeconds = Double(recurrenceFrequency) * 30 * 24 * 3600
        default:
            break
        }
        
        // Calculate next occurrence
        var currentDate = date.addingTimeInterval(intervalInSeconds)
        if currentDate <= recurrenceEndDate {
            occurrences.append(currentDate)
        }
        
        return occurrences
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Save Event Function
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
        
        // Handle recurrence settings
        if isRecurring {
            let recurrenceSettings = UserDefaults.standard.dictionary(forKey: "EventRecurrenceSettings") as? [String: [String: Any]] ?? [:]
            var updatedRecurrenceSettings = recurrenceSettings
            
            updatedRecurrenceSettings[newEvent.id!] = [
                "isRecurring": true,
                "recurrenceType": recurrenceType,
                "recurrenceFrequency": recurrenceFrequency,
                "recurrenceEndDate": recurrenceEndDate.timeIntervalSince1970
            ]
            
            UserDefaults.standard.set(updatedRecurrenceSettings, forKey: "EventRecurrenceSettings")
            
            // Create recurring events
            createRecurringEvents(baseEvent: newEvent)
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
    
    private func createRecurringEvents(baseEvent: Event) {
        // Calculate the interval for recurrence
        var intervalInSeconds: TimeInterval = 0
        
        switch recurrenceType {
        case 0: // Daily
            intervalInSeconds = Double(recurrenceFrequency) * 24 * 3600
        case 1: // Weekly
            intervalInSeconds = Double(recurrenceFrequency) * 7 * 24 * 3600
        case 2: // Monthly
            // Approximate a month as 30 days
            intervalInSeconds = Double(recurrenceFrequency) * 30 * 24 * 3600
        default:
            return
        }
        
        // Create a record for recurring events
        var recurringEventIds = UserDefaults.standard.dictionary(forKey: "RecurringEventSeries") as? [String: [String]] ?? [:]
        
        var seriesIds: [String] = []
        seriesIds.append(baseEvent.id!)
        
        // Create recurring instances
        var currentDate = date.addingTimeInterval(intervalInSeconds)
        while currentDate <= recurrenceEndDate {
            let recurringEvent = Event(context: viewContext)
            recurringEvent.id = UUID().uuidString
            recurringEvent.title = title
            recurringEvent.location = location
            recurringEvent.eventDescription = description
            recurringEvent.date = currentDate
            recurringEvent.ageRange = ageRange
            
            // Copy participant limits
            if hasParticipantLimit {
                recurringEvent.capacity = Int32(maxChildrenCount)
                recurringEvent.spotsRemaining = Int32(maxChildrenCount)
            } else {
                recurringEvent.capacity = -1
                recurringEvent.spotsRemaining = -1
            }
            
            // Copy pricing
            if isPaid {
                recurringEvent.isPaid = currentDate
                if let priceValue = Decimal(string: price) {
                    recurringEvent.price = NSDecimalNumber(decimal: priceValue)
                }
            }
            
            // Copy privacy settings
            let privacySettings = UserDefaults.standard.dictionary(forKey: "EventPrivacySettings") as? [String: Int] ?? [:]
            var updatedSettings = privacySettings
            updatedSettings[recurringEvent.id!] = privacyOption
            UserDefaults.standard.set(updatedSettings, forKey: "EventPrivacySettings")
            
            // Copy participant limit description if available
            if hasParticipantLimit && !limitDescription.isEmpty {
                let limitDescriptions = UserDefaults.standard.dictionary(forKey: "EventLimitDescriptions") as? [String: String] ?? [:]
                var updatedLimitDescriptions = limitDescriptions
                updatedLimitDescriptions[recurringEvent.id!] = limitDescription
                UserDefaults.standard.set(updatedLimitDescriptions, forKey: "EventLimitDescriptions")
            }
            
            // Add to series
            seriesIds.append(recurringEvent.id!)
            
            // Move to next occurrence
            currentDate = currentDate.addingTimeInterval(intervalInSeconds)
        }
        
        // Store the series IDs
        recurringEventIds[baseEvent.id!] = seriesIds
        UserDefaults.standard.set(recurringEventIds, forKey: "RecurringEventSeries")
    }
}

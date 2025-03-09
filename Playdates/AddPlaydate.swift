import SwiftUI
import CoreData

struct AddPlaydateView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    // Form fields
    @State private var title = ""
    @State private var location = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var ageRangeSelection = 1  // Index in ageRanges array
    @State private var privacyOption = 0 // 0=Public, 1=Friends, 2=Private
    
    // Participant limits
    @State private var maxChildrenCount = 4
    
    // Children attending from host
    @State private var childrenAttending = 1
    
    // Error handling
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Available age ranges
    let ageRanges = ["0-2 years", "3-5 years", "6-8 years", "9-12 years", "Teenagers"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Playdate Details")) {
                    TextField("Playdate Title", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("Date & Time", selection: $date)
                    
                    Picker("Age Range", selection: $ageRangeSelection) {
                        ForEach(0..<ageRanges.count, id: \.self) { index in
                            Text(ageRanges[index]).tag(index)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe the playdate, what activities are planned, what to bring, etc.")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                }
                
                Section(header: Text("Privacy")) {
                    Picker("Who can see this playdate?", selection: $privacyOption) {
                        Text("Public").tag(0)
                        Text("Friends Only").tag(1)
                        Text("Private (Invite Only)").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Participant Limits")) {
                    HStack {
                        Text("Maximum number of children:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(maxChildrenCount)")
                            .font(.headline)
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    
                    Stepper("", value: $maxChildrenCount, in: 1...20)
                    
                    Text("This limits the total number of children that can attend the playdate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Your Children Attending")) {
                    HStack {
                        Text("Your children attending:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(childrenAttending)")
                            .font(.headline)
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                    
                    Stepper("", value: $childrenAttending, in: 1...4)
                    
                    Text("How many of your children will be attending this playdate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: savePlaydate) {
                    Text("Create Playdate")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Create Playdate")
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
    
    private func savePlaydate() {
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
        
        // In a real app, this would save to Core Data
        // For now, we'll just dismiss the sheet
        
        // Create a new Playdate entity in Core Data
        let newPlaydate = Playdate(context: viewContext)
        newPlaydate.id = UUID().uuidString
        newPlaydate.time = date
        newPlaydate.location = location
        newPlaydate.parentName = "You" // In a real app, this would be the current user's name
        newPlaydate.playdateDescription = description
        newPlaydate.attendingCount = Int32(childrenAttending)
        
        // Set visibility based on privacy option
        switch privacyOption {
        case 1:
            newPlaydate.visibility = "Friends"
        case 2:
            newPlaydate.visibility = "Private"
        default:
            newPlaydate.visibility = "Public"
        }
        
        // Save to Core Data
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Could not save playdate: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

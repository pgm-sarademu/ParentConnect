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
    @State private var privacyOption = 0 // 0=Public, 1=Friends, 2=Private
    
    // Participant limits
    @State private var maxChildrenCount = 4
    
    // Children attending from host
    @State private var childrenAttending = 1
    
    // Error handling
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Safety Reminder
                Section {
                    // Safety Reminder Alert
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Safety Reminder")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("For safety, we recommend meeting in public spaces and supervising children during playdates.")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
                
                // MARK: - Playdate Details
                Section {
                    TextField("Playdate Title", text: $title)
                        .font(.body)
                    
                    TextField("Location", text: $location)
                        .font(.body)
                    
                    DatePicker("Date & Time", selection: $date)
                        .font(.body)
                } header: {
                    Text("Playdate Details")
                }
                
                // MARK: - Description
                Section {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .font(.body)
                        .overlay(
                            Group {
                                if description.isEmpty {
                                    Text("Describe the playdate, what activities are planned, what to bring, etc.")
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
                
                // MARK: - Privacy
                Section {
                    Picker("Who can see this playdate?", selection: $privacyOption) {
                        Text("Public").tag(0)
                        Text("Friends Only").tag(1)
                        Text("Private (Invite Only)").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Privacy")
                }
                
                // MARK: - Participant Numbers
                Section {
                    HStack {
                        Text("Maximum children")
                        Spacer()
                        Stepper("\(maxChildrenCount)", value: $maxChildrenCount, in: 1...20)
                            .fixedSize()
                    }
                    
                    HStack {
                        Text("Your children attending")
                        Spacer()
                        Stepper("\(childrenAttending)", value: $childrenAttending, in: 1...4)
                            .fixedSize()
                    }
                } header: {
                    Text("Participant Limits")
                }
                
                // MARK: - Create Button
                Section {
                    Button(action: savePlaydate) {
                        Text("Create Playdate")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color("AppPrimaryColor"))
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Create Playdate")
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

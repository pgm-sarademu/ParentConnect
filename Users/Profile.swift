import SwiftUI

struct Profile: View {
    @State private var showingEditProfile = false
    @State private var showingFeedbackSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingConnectionsView = false
    
    // Mock user data - in a real app this would come from Core Data or other storage
    @State private var user = MockUser.current
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color("AppPrimaryColor").opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle().stroke(Color("AppPrimaryColor"), lineWidth: 3)
                                )
                                .shadow(radius: 5)
                            
                            Text("👩‍👦")
                                .font(.system(size: 50))
                        }
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let location = user.location {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Text("Edit Profile")
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color("AppPrimaryColor"), lineWidth: 1)
                                )
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Children section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("My Children")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if let children = user.children, !children.isEmpty {
                            ForEach(children) { child in
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color("AppPrimaryColor").opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Text(child.age < 3 ? "👶" : "🧒")
                                            .font(.title2)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(child.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text("\(child.age) years old")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Edit child info
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                // Add another child
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Another Child")
                                }
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        } else {
                            HStack {
                                Spacer()
                                Button(action: {
                                    // Add child
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Child")
                                    }
                                    .foregroundColor(Color("AppPrimaryColor"))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // New section for App Activity
                    VStack(alignment: .leading, spacing: 15) {
                        Text("App Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Event History Button
                        NavigationLink(destination: EventHistory()) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.primary)
                                Text("Event History")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("8 events")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Created Events Button (NEW)
                        NavigationLink(destination: CreatedEvents()) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.primary)
                                Text("Created Events")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("3 events")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Connections Button
                        Button(action: {
                            showingConnectionsView = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.primary)
                                Text("Connections")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("5 parents")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Settings & preferences section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Settings & Preferences")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // App Ideas button
                        Button(action: {
                            showingFeedbackSheet = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.primary)
                                Text("Submit App Ideas")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Privacy preferences
                        Button(action: {
                            showingPrivacySettings = true
                        }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(.primary)
                                Text("Privacy Preferences")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                        
                        // Notification settings
                        Button(action: {
                            showingNotificationSettings = true
                        }) {
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(.primary)
                                Text("Notification Settings")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    // Logout button
                    Button(action: {
                        // Handle logout
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfile(user: $user)
            }
            .sheet(isPresented: $showingFeedbackSheet) {
                Feedback()
            }
            .sheet(isPresented: $showingConnectionsView) {
                NavigationView {
                    Connections()
                }
            }
        }
    }
}

// Mock user model
struct MockUser {
    var id: String
    var name: String
    var email: String
    var location: String?
    var children: [MockChild]?
    
    // Sample user data
    static let current = MockUser(
        id: "1",
        name: "Sara Demulder",
        email: "sara@example.com",
        location: "Amsterdam, Netherlands",
        children: [
            MockChild(id: "1", name: "Emma", age: 4),
            MockChild(id: "2", name: "Liam", age: 2)
        ]
    )
}

struct MockChild: Identifiable {
    var id: String
    var name: String
    var age: Int
}

struct EditProfile: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var user: MockUser
    
    @State private var name: String
    @State private var location: String
    
    init(user: Binding<MockUser>) {
        self._user = user
        self._name = State(initialValue: user.wrappedValue.name)
        self._location = State(initialValue: user.wrappedValue.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    TextField("Location", text: $location)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func saveChanges() {
        user.name = name
        user.location = location
    }
}

struct Feedback: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackType = "Feature Request"
    @State private var feedbackText = ""
    @State private var contactEmail = ""
    @State private var showingSuccessAlert = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    let feedbackTypes = ["Feature Request", "Bug Report", "Content Suggestion", "General Feedback"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feedback Type")) {
                    Picker("Type", selection: $feedbackType) {
                        ForEach(feedbackTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Your Ideas")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if feedbackText.isEmpty {
                                    Text("Tell us how we can improve ParentConnect...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }
                        )
                }
                
                Section(header: Text("Contact Information (Optional)")) {
                    TextField("Email for follow-up", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button(action: submitFeedback) {
                        Text("Submit Feedback")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Submit App Ideas")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Thank You!"),
                    message: Text("Your ideas have been received. We appreciate your help in making ParentConnect better!"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .alert("Cannot Submit Feedback", isPresented: $showingValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func submitFeedback() {
        // Validate inputs
        if feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please enter your feedback or suggestion."
            showingValidationAlert = true
            return
        }
        
        // In a real app, this would send the feedback to a server
        // For now, we'll just show a success message
        
        // Show success message
        showingSuccessAlert = true
    }
}

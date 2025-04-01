import SwiftUI

// Mock user model
struct MockUser {
    var id: String
    var name: String
    var email: String
    var location: String?
    var bio: String?
    var children: [MockChild]?
    
    // Sample user data
    static let current = MockUser(
        id: "1",
        name: "Sara Demulder",
        email: "sara@example.com",
        location: "Amsterdam, Netherlands",
        bio: "Parent of two wonderful children. Love organizing playdates and community activities.",
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

struct Profile: View {
    @State private var showingEditProfile = false
    @State private var showingFeedbackSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingConnectionsView = false
    @State private var showingAddChildSheet = false
    
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
                                .shadow(radius: 3)
                            
                            Text("👩‍👦")
                                .font(.system(size: 50))
                        }
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 10)
                        
                        if let location = user.location {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 14))
                                Text(location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 2)
                        }
                        
                        if let bio = user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 5)
                        }
                        
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Profile")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(20)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // Children section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("My Children")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        if let children = user.children, !children.isEmpty {
                            ForEach(children) { child in
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color("AppPrimaryColor").opacity(0.2))
                                            .frame(width: 50, height: 50)
                                        
                                        Text(child.age < 3 ? "👶" : "🧒")
                                            .font(.title2)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(child.name)
                                            .font(.headline)
                                        
                                        Text("\(child.age) years old")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Edit child info
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(Color("AppPrimaryColor"))
                                            .font(.system(size: 16))
                                            .padding(8)
                                            .background(Color("AppPrimaryColor").opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                .padding(.horizontal)
                            }
                            
                            Button(action: {
                                showingAddChildSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Child")
                                }
                                .font(.subheadline)
                                .foregroundColor(Color("AppPrimaryColor"))
                                .padding(.vertical, 8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 5)
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "person.2.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(.systemGray4))
                                    
                                    Text("No children added yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        showingAddChildSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Child")
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color("AppPrimaryColor"))
                                        .cornerRadius(20)
                                    }
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
                    .padding(.vertical, 10)
                    
                    // App Activity section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("App Activity")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Event History Button
                        NavigationLink(destination: EventHistory()) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Event History")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("8 events")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Created Events Button
                        NavigationLink(destination: CreatedEvents()) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Created Events")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("3 events")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Connections Button
                        Button(action: {
                            showingConnectionsView = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Connections")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("5 parents")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    // Settings & preferences section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Settings & Preferences")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // App Ideas button
                        Button(action: {
                            showingFeedbackSheet = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Submit App Ideas")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Privacy preferences
                        Button(action: {
                            showingPrivacySettings = true
                        }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Privacy Preferences")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // Notification settings
                        Button(action: {
                            showingNotificationSettings = true
                        }) {
                            HStack {
                                Image(systemName: "bell")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                    .font(.system(size: 20))
                                    .frame(width: 24, height: 24)
                                
                                Text("Notification Settings")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)
                    
                    // Logout button
                    Button(action: {
                        // Handle logout
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
                .padding(.top)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
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
            .sheet(isPresented: $showingAddChildSheet) {
                AddChild(user: $user)
            }
        }
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

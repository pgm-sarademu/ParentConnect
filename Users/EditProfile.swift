import SwiftUI

struct EditProfile: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var user: MockUser
    
    @State private var name: String
    @State private var location: String
    @State private var bio: String
    @State private var email: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingLocationSelector = false
    
    init(user: Binding<MockUser>) {
        self._user = user
        self._name = State(initialValue: user.wrappedValue.name)
        self._location = State(initialValue: user.wrappedValue.location ?? "")
        
        // Set a default bio for the current user
        let defaultBio = user.wrappedValue.id == "1" ?
            "Parent of two wonderful children. Love organizing playdates and community activities." : ""
        self._bio = State(initialValue: user.wrappedValue.bio ?? defaultBio)
        
        self._email = State(initialValue: user.wrappedValue.email)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile picture section
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color("AppPrimaryColor").opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle().stroke(Color("AppPrimaryColor"), lineWidth: 3)
                                )
                            
                            Text("👩‍👦")
                                .font(.system(size: 50))
                            
                            // Camera icon for profile picture change
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(Color("AppPrimaryColor"))
                                )
                                .shadow(radius: 2)
                                .offset(x: 45, y: 45)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Form fields
                    VStack(spacing: 15) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Your name", text: $name)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .disableAutocorrection(true)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextField("Your email", text: $email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Location Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingLocationSelector = true
                            }) {
                                HStack {
                                    Text(location.isEmpty ? "Select your location" : location)
                                        .foregroundColor(location.isEmpty ? .gray : .primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(Color("AppPrimaryColor"))
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Bio Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $bio)
                                .frame(minHeight: 100)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .overlay(
                                    Group {
                                        if bio.isEmpty {
                                            Text("Tell others about yourself...")
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 12)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save button
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AppPrimaryColor"))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Profile")
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
            .sheet(isPresented: $showingLocationSelector) {
                LocationSelector(selectedLocation: $location)
            }
        }
    }
    
    private func saveChanges() {
        // Basic validation
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter your name"
            showingAlert = true
            return
        }
        
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter your email"
            showingAlert = true
            return
        }
        
        // Update user model
        user.name = name
        user.email = email
        user.location = location
        user.bio = bio
        
        // Simply dismiss the view without showing a success message
        presentationMode.wrappedValue.dismiss()
    }
    
    private func showErrorAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}

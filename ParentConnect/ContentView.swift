import SwiftUI
import CoreData
import MapKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isLoggedIn = false
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        if isLoggedIn {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                    .tag(1)
                
                EventsView()
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                    .tag(2)
                
                ActivitiesView()
                    .tabItem {
                        Label("Activities", systemImage: "doc.fill")
                    }
                    .tag(3)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(4)
            }
            .accentColor(Color("AppPrimaryColor"))
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

// Simple login view
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 25) {
            // App logo/icon
            Image(systemName: "figure.2.and.child.holdinghands.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color("AppPrimaryColor"))
                .padding(.bottom, 20)
            
            Text("Parent Connect")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color("AppPrimaryColor"))
            
            Text("Connect with parents, arrange playdates, and discover activities for your kids")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            
            // Username field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email or Username")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $username)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            if showError {
                Text("Invalid username or password")
                    .foregroundColor(.red)
            }
            
            // Sign in button
            Button(action: {
                // For demo purposes, accept any input
                // In a real app, this would authenticate with your backend
                isLoggedIn = true
            }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppPrimaryColor"))
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            // Demo mode button
            Button(action: {
                isLoggedIn = true
            }) {
                Text("Demo Mode")
                    .font(.headline)
                    .foregroundColor(Color("AppPrimaryColor"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppPrimaryColor").opacity(0.1))
                    .cornerRadius(10)
            }
            
            Spacer()
            
            // Sign up option
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Navigate to sign up view
                }) {
                    Text("Sign Up")
                        .fontWeight(.bold)
                        .foregroundColor(Color("AppPrimaryColor"))
                }
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(LocationManager())
            .environmentObject(NotificationManager.shared)
    }
}

import SwiftUI
import CoreData

struct EventParticipantView: View {
    let eventId: String
    @State private var attendees: [MockAttendee] = []
    @State private var isLoading = true
    @State private var showingConnectConfirmation = false
    @State private var selectedAttendee: MockAttendee?
    @State private var hasParticipantLimit = false
    @State private var maxChildCount = 0
    @State private var currentChildCount = 0
    
    var body: some View {
        VStack {
            // If there's a participant limit, show a capacity indicator
            if hasParticipantLimit {
                VStack(spacing: 5) {
                    HStack {
                        Text("Event Capacity")
                            .font(.headline)
                        Spacer()
                        Text("\(currentChildCount)/\(maxChildCount) children")
                            .font(.subheadline)
                            .foregroundColor(currentChildCount >= maxChildCount ? .red : .secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 8)
                                .opacity(0.2)
                                .foregroundColor(Color("AppPrimaryColor"))
                                .cornerRadius(4)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(currentChildCount) / CGFloat(maxChildCount) * geometry.size.width, geometry.size.width), height: 8)
                                .foregroundColor(currentChildCount >= maxChildCount ? .red : Color("AppPrimaryColor"))
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            
            if isLoading {
                ProgressView("Loading participants...")
            } else if attendees.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(Color(.systemGray4))
                    
                    Text("No participants yet")
                        .font(.headline)
                    
                    Text("Be the first to attend this event!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                List {
                    Section(header: Text("People attending this event")) {
                        ForEach(attendees) { attendee in
                            HStack {
                                // Avatar placeholder
                                ZStack {
                                    Circle()
                                        .fill(Color("AppPrimaryColor").opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Text("👤")
                                        .font(.title)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(attendee.name)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(attendee.childrenInfo)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        // Child count badge
                                        Text("\(attendee.childCount)")
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color("AppPrimaryColor"))
                                            .foregroundColor(.white)
                                            .clipShape(Circle())
                                    }
                                }
                                
                                Spacer()
                                
                                if attendee.isConnected {
                                    Text("Connected")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                } else {
                                    Button(action: {
                                        selectedAttendee = attendee
                                        showingConnectConfirmation = true
                                    }) {
                                        Text("Connect")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color("AppPrimaryColor"))
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Summary section
                    Section(header: Text("Summary")) {
                        HStack {
                            Text("Total parents:")
                            Spacer()
                            Text("\(attendees.count)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Total children:")
                            Spacer()
                            Text("\(currentChildCount)")
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .navigationTitle("Participants")
        .onAppear(perform: loadAttendees)
        .alert(isPresented: $showingConnectConfirmation) {
            Alert(
                title: Text("Connect with \(selectedAttendee?.name ?? "this parent")"),
                message: Text("Would you like to send a connection request? This will allow you to message each other."),
                primaryButton: .default(Text("Connect")) {
                    connectWithAttendee()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func loadAttendees() {
        // In a real app, you would fetch this from Core Data or your API
        // For now, we'll simulate loading with some mock data
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check event ID and load appropriate mock data
            // In a real app, you would fetch actual attendees for this event
            self.attendees = [
                MockAttendee(id: "1", name: "Sarah Johnson", childrenInfo: "2 kids (4, 6)", childCount: 2, isConnected: false),
                MockAttendee(id: "2", name: "Mike Thompson", childrenInfo: "1 kid (3)", childCount: 1, isConnected: true),
                MockAttendee(id: "3", name: "Emma Roberts", childrenInfo: "3 kids (2, 5, 7)", childCount: 3, isConnected: false),
                MockAttendee(id: "4", name: "David Wilson", childrenInfo: "2 kids (4, 8)", childCount: 2, isConnected: false),
                MockAttendee(id: "5", name: "Jennifer Brown", childrenInfo: "1 kid (5)", childCount: 1, isConnected: false)
            ]
            
            // Calculate total children count
            self.currentChildCount = self.attendees.reduce(0) { $0 + $1.childCount }
            
            // For demo, determine if this event has a participant limit
            let idValue = Int(eventId) ?? 0
            self.hasParticipantLimit = idValue % 3 == 0 // Every third event has a limit
            
            if self.hasParticipantLimit {
                self.maxChildCount = 15 // Demo value
            }
            
            isLoading = false
        }
    }
    
    private func connectWithAttendee() {
        guard let attendee = selectedAttendee else { return }
        
        // In a real app, you would:
        // 1. Send a connection request to the backend
        // 2. Store the connection in Core Data
        // 3. Update the UI
        
        // For now, we'll just update our local state
        if let index = attendees.firstIndex(where: { $0.id == attendee.id }) {
            attendees[index].isConnected = true
        }
        
        // In a real app, you would also navigate to a message screen or show confirmation
    }
}

// Simple mock model for demonstration
struct MockAttendee: Identifiable {
    let id: String
    let name: String
    let childrenInfo: String
    let childCount: Int
    var isConnected: Bool
}

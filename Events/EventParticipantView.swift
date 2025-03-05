import SwiftUI
import CoreData

struct EventParticipantView: View {
    let eventId: String
    @State private var attendees: [MockAttendee] = []
    @State private var isLoading = true
    @State private var showingConnectConfirmation = false
    @State private var selectedAttendee: MockAttendee?
    
    var body: some View {
        VStack {
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
                                    
                                    Text(attendee.childrenInfo)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
                MockAttendee(id: "1", name: "Sarah Johnson", childrenInfo: "2 kids (4, 6)", isConnected: false),
                MockAttendee(id: "2", name: "Mike Thompson", childrenInfo: "1 kid (3)", isConnected: true),
                MockAttendee(id: "3", name: "Emma Roberts", childrenInfo: "3 kids (2, 5, 7)", isConnected: false)
            ]
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
    var isConnected: Bool
}

import SwiftUI
import CoreData

// View to display and manage event participants
struct EventParticipantsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let eventId: String
    let isCreator: Bool
    
    @State private var participants: [ParticipantViewModel] = []
    @State private var selectedParticipantId: String? = nil
    @State private var showingActionSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            if participants.isEmpty {
                Text("No participants yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(participants) { participant in
                    ParticipantRow(participant: participant, isCreator: isCreator)
                        .onTapGesture {
                            if isCreator {
                                selectedParticipantId = participant.id
                                showingActionSheet = true
                            }
                        }
                }
            }
        }
        .navigationTitle("Participants")
        .onAppear {
            loadParticipants()
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Manage Participant"),
                message: Text("What would you like to do?"),
                buttons: [
                    .destructive(Text("Remove from Event")) {
                        if let participantId = selectedParticipantId {
                            removeParticipant(participantId: participantId)
                        }
                    },
                    .default(Text("Message")) {
                        // Start a conversation with the participant
                        // This would integrate with your existing messaging system
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Participant Management"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func loadParticipants() {
        // In a real app, this would fetch actual participants from Core Data
        // using the EventParticipationManager
        
        // Mock data for now
        participants = [
            ParticipantViewModel(id: "user1", name: "Sarah Johnson", joinDate: Date().addingTimeInterval(-86400), privacyLevel: "Public"),
            ParticipantViewModel(id: "user2", name: "Mike Thompson", joinDate: Date().addingTimeInterval(-172800), privacyLevel: "Friends Only"),
            ParticipantViewModel(id: "user3", name: "Emma Roberts", joinDate: Date().addingTimeInterval(-259200), privacyLevel: "Public")
        ]
    }
    
    private func removeParticipant(participantId: String) {
        // In a real app, this would use the EventParticipationManager to remove the participant
        let manager = EventParticipationManager.shared
        let success = manager.removeParticipant(eventId: eventId, participantId: participantId, context: viewContext)
        
        if success {
            alertMessage = "Participant removed successfully"
            showingAlert = true
            
            // Remove from the local array to update the UI
            if let index = participants.firstIndex(where: { $0.id == participantId }) {
                participants.remove(at: index)
            }
        } else {
            alertMessage = "Failed to remove participant"
            showingAlert = true
        }
    }
}

// Model for participant information
struct ParticipantViewModel: Identifiable {
    let id: String
    let name: String
    let joinDate: Date
    let privacyLevel: String
    
    // Can include more fields like profile image, etc.
}

// Row view for a single participant
struct ParticipantRow: View {
    let participant: ParticipantViewModel
    let isCreator: Bool
    
    var body: some View {
        HStack {
            // Avatar
            Circle()
                .fill(Color("AppPrimaryColor").opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("👤")
                        .font(.system(size: 20))
                )
            
            // Name and join date
            VStack(alignment: .leading) {
                Text(participant.name)
                    .font(.headline)
                
                Text("Joined \(formatDate(participant.joinDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Privacy indicator
            if participant.privacyLevel != "Public" {
                Image(systemName: "eye.slash")
                    .foregroundColor(.secondary)
                    .help("This participant's attendance is not publicly visible")
            }
            
            // Creator controls
            if isCreator {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// View to invite friends to an event
struct EventInviteView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let eventId: String
    
    @State private var friends: [FriendViewModel] = []
    @State private var searchText = ""
    @State private var selectedFriendIds: Set<String> = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var filteredFriends: [FriendViewModel] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            TextField("Search friends", text: $searchText)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 10)
            
            // Friend list
            List {
                ForEach(filteredFriends) { friend in
                    HStack {
                        // Avatar
                        Circle()
                            .fill(Color("AppPrimaryColor").opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("👤")
                                    .font(.system(size: 20))
                            )
                        
                        // Name and details
                        VStack(alignment: .leading) {
                            Text(friend.name)
                                .font(.headline)
                            
                            if let childrenInfo = friend.childrenInfo {
                                Text(childrenInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Selection checkmark
                        Image(systemName: selectedFriendIds.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedFriendIds.contains(friend.id) ? Color("AppPrimaryColor") : .gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedFriendIds.contains(friend.id) {
                            selectedFriendIds.remove(friend.id)
                        } else {
                            selectedFriendIds.insert(friend.id)
                        }
                    }
                }
            }
            
            // Invite button
            Button(action: inviteFriends) {
                Text("Invite Selected Friends (\(selectedFriendIds.count))")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppPrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .disabled(selectedFriendIds.isEmpty)
            .padding(.bottom)
        }
        .navigationTitle("Invite Friends")
        .onAppear {
            loadFriends()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Friend Invitations"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func loadFriends() {
        // In a real app, this would fetch the user's friends from Core Data
        
        // Mock data
        friends = [
            FriendViewModel(id: "friend1", name: "Sarah Johnson", childrenInfo: "2 kids (4, 6)"),
            FriendViewModel(id: "friend2", name: "Mike Thompson", childrenInfo: "1 kid (3)"),
            FriendViewModel(id: "friend3", name: "Emma Roberts", childrenInfo: "3 kids (2, 5, 7)"),
            FriendViewModel(id: "friend4", name: "David Wilson", childrenInfo: "1 kid (4)"),
            FriendViewModel(id: "friend5", name: "Olivia Garcia", childrenInfo: "2 kids (3, 6)")
        ]
    }
    
    private func inviteFriends() {
        // In a real app, this would use the EventParticipationManager to send invitations
        let manager = EventParticipationManager.shared
        var successCount = 0
        
        for friendId in selectedFriendIds {
            let success = manager.inviteUserToEvent(
                eventId: eventId,
                userId: "currentUserId", // Current user ID
                inviteeId: friendId,
                context: viewContext
            )
            
            if success {
                successCount += 1
            }
        }
        
        if successCount > 0 {
            alertMessage = "Successfully sent \(successCount) invitation\(successCount > 1 ? "s" : "")"
            showingAlert = true
        } else {
            alertMessage = "Failed to send invitations"
            showingAlert = true
        }
    }
}

// Model for friend information
struct FriendViewModel: Identifiable {
    let id: String
    let name: String
    let childrenInfo: String?
}

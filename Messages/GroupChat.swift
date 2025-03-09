import SwiftUI

struct EventChatStatus {
    let isActive: Bool
    let participantCount: Int
    let unreadMessageCount: Int
}

struct GroupMessage: Identifiable {
    let id: String
    let senderName: String
    let senderAvatar: String
    let text: String
    let timestamp: Date
    let isFromCurrentUser: Bool
}

struct Participant: Identifiable {
    let id: String
    let name: String
    let avatar: String
    let childrenInfo: String
}

struct GroupChat: View {
    let eventId: String
    let eventTitle: String
    @State private var messages: [GroupMessage] = []
    @State private var newMessageText = ""
    @State private var participants: [Participant] = []
    @State private var isShowingParticipants = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack {
            // Group chat header with participant count
            HStack {
                Text("\(participants.count) participants")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    isShowingParticipants = true
                }) {
                    HStack {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor"))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack {
                        ForEach(messages) { message in
                            GroupMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                
                // This is iOS 17+ compatible with fallback for older versions
                #if swift(>=5.9)
                // iOS 17 and newer
                .onChange(of: messages.count) { oldCount, newCount in
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                #else
                // iOS 16 and older
                .onChange(of: messages.count) { newCount in
                    if let lastMessage = messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                #endif
            }
            
            // Message input
            HStack {
                Button(action: {
                    // Add attachment
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("AppPrimaryColor"))
                }
                
                TextField("Message", text: $newMessageText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .focused($isInputFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("AppPrimaryColor"))
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        }
        .navigationTitle("Event Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMockMessages()
            loadMockParticipants()
        }
        .sheet(isPresented: $isShowingParticipants) {
            ParticipantList(participants: participants, eventTitle: eventTitle)
        }
    }
    
    private func loadMockMessages() {
        messages = [
            GroupMessage(
                id: "1",
                senderName: "Sarah Johnson",
                senderAvatar: "👩‍👧",
                text: "Hi everyone! Is anyone planning to bring snacks to the event?",
                timestamp: Date().addingTimeInterval(-3600*3),
                isFromCurrentUser: false
            ),
            GroupMessage(
                id: "2",
                senderName: "Mike Thompson",
                senderAvatar: "👨‍👦",
                text: "I can bring some fruit and juice boxes for the kids.",
                timestamp: Date().addingTimeInterval(-3600*2),
                isFromCurrentUser: false
            ),
            GroupMessage(
                id: "3",
                senderName: "Emma Roberts",
                senderAvatar: "👩‍👧‍👦",
                text: "Great! I'll bring some veggie sticks and dip.",
                timestamp: Date().addingTimeInterval(-3600),
                isFromCurrentUser: false
            ),
            GroupMessage(
                id: "4",
                senderName: "You",
                senderAvatar: "👩‍👦",
                text: "Sounds good! I'll bring some cookies then.",
                timestamp: Date().addingTimeInterval(-1800),
                isFromCurrentUser: true
            ),
            GroupMessage(
                id: "5",
                senderName: "David Wilson",
                senderAvatar: "👨‍👧",
                text: "Looking forward to meeting everyone's kids!",
                timestamp: Date(),
                isFromCurrentUser: false
            )
        ]
    }
    
    private func loadMockParticipants() {
        participants = [
            Participant(id: "1", name: "Sarah Johnson", avatar: "👩‍👧", childrenInfo: "2 kids (4, 6)"),
            Participant(id: "2", name: "Mike Thompson", avatar: "👨‍👦", childrenInfo: "1 kid (3)"),
            Participant(id: "3", name: "Emma Roberts", avatar: "👩‍👧‍👦", childrenInfo: "3 kids (2, 5, 7)"),
            Participant(id: "4", name: "You", avatar: "👩‍👦", childrenInfo: "2 kids (4, 2)"),
            Participant(id: "5", name: "David Wilson", avatar: "👨‍👧", childrenInfo: "2 kids (4, 8)"),
            Participant(id: "6", name: "Jennifer Brown", avatar: "👩‍👦‍👦", childrenInfo: "2 kids (3, 5)"),
            Participant(id: "7", name: "Michael Scott", avatar: "👨‍👧‍👦", childrenInfo: "2 kids (4, 7)")
        ]
    }
    
    private func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = GroupMessage(
            id: UUID().uuidString,
            senderName: "You",
            senderAvatar: "👩‍👦",
            text: newMessageText,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        
        messages.append(newMessage)
        newMessageText = ""
    }
}

struct ParticipantList: View {
    let participants: [Participant]
    let eventTitle: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(participants) { participant in
                    HStack {
                        Text(participant.avatar)
                            .font(.title)
                            .frame(width: 40, height: 40)
                            .background(Color("AppPrimaryColor").opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(participant.name)
                                .font(.headline)
                            
                            Text(participant.childrenInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if participant.name != "You" {
                            NavigationLink(destination: ChatView(conversation: ConversationPreview(
                                id: participant.id,
                                participantName: participant.name,
                                lastMessage: "",
                                timestamp: Date(),
                                unread: false
                            ))) {
                                EmptyView()
                            }
                            .frame(width: 20)
                            .opacity(0)
                            
                            Button(action: {
                                // Open direct message
                            }) {
                                Image(systemName: "message")
                                    .foregroundColor(Color("AppPrimaryColor"))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("\(eventTitle) Participants")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct GroupMessageBubble: View {
    let message: GroupMessage
    
    var body: some View {
        VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
            if !message.isFromCurrentUser {
                HStack {
                    Text(message.senderAvatar)
                        .font(.headline)
                        .frame(width: 24, height: 24)
                    
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 2)
            }
            
            HStack {
                if message.isFromCurrentUser { Spacer() }
                
                VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                    Text(message.text)
                        .padding(10)
                        .background(message.isFromCurrentUser ? Color("AppPrimaryColor") : Color(.systemGray5))
                        .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                        .cornerRadius(16)
                    
                    Text(formatMessageTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                if !message.isFromCurrentUser { Spacer() }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

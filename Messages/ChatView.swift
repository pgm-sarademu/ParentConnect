import SwiftUI

struct MessagePreview: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
    let isFromCurrentUser: Bool
}

struct MessageBubble: View {
    let message: MessagePreview
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(10)
                    .background(isFromCurrentUser ? Color("AppPrimaryColor") : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(formatMessageTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ChatView: View {
    let conversation: ConversationPreview
    @State private var messages: [MessagePreview] = []
    @State private var newMessageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var showUserCard = false
    @State private var userCardOffset: CGFloat = 400
    
    // Mock participant data - in a real app, this would come from your data model
    @State private var participant = ParticipantInfo(
        id: "123",
        name: "Sarah Johnson",
        location: "Brooklyn, NY",
        bio: "Mom of two. Love outdoor activities and arts & crafts.",
        children: [
            ChildInfo(id: "1", name: "Emma", age: 4),
            ChildInfo(id: "2", name: "Noah", age: 2)
        ]
    )
    
    var body: some View {
        ZStack {
            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isFromCurrentUser: message.isFromCurrentUser)
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
                    
                    // Updated onChange for iOS 17+ compatibility with fallback for older versions
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
            
            // Overlay for user card
            if showUserCard {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideUserCard()
                    }
                
                UserCard(
                    user: participant,
                    isPresented: $showUserCard,
                    onConnectTapped: { isConnected in
                        // Handle connection change
                        print("Connection status changed to: \(isConnected)")
                    }
                )
                .offset(y: userCardOffset)
                .animation(.spring(dampingFraction: 0.7), value: userCardOffset)
            }
        }
        .navigationTitle(conversation.participantName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    displayUserCard()
                }) {
                    HStack(spacing: 4) {
                        Text(conversation.participantName)
                            .font(.headline)
                        
                        Image(systemName: "info.circle")
                            .font(.caption)
                    }
                }
            }
        }
        .onAppear {
            loadMockMessages()
            // Update participant name to match conversation
            participant = ParticipantInfo(
                id: "123",
                name: conversation.participantName,
                location: "Brooklyn, NY",
                bio: "Mom of two. Love outdoor activities and arts & crafts.",
                children: [
                    ChildInfo(id: "1", name: "Emma", age: 4),
                    ChildInfo(id: "2", name: "Noah", age: 2)
                ]
            )
        }
    }
    
    private func loadMockMessages() {
        messages = [
            MessagePreview(id: "1", text: "Hi there! I noticed you have kids around the same age as mine. Would you be interested in arranging a playdate?", timestamp: Date().addingTimeInterval(-259200), isFromCurrentUser: false),
            MessagePreview(id: "2", text: "Hello! That sounds great. My kids would love that. What days usually work best for you?", timestamp: Date().addingTimeInterval(-172800), isFromCurrentUser: true),
            MessagePreview(id: "3", text: "We usually have free time on weekends, especially Saturday afternoons. How about you?", timestamp: Date().addingTimeInterval(-86400), isFromCurrentUser: false),
            MessagePreview(id: "4", text: "Weekends work for us too! Would this Saturday around 2pm at Central Park playground work?", timestamp: Date().addingTimeInterval(-3600), isFromCurrentUser: true),
            MessagePreview(id: "5", text: "Would Saturday afternoon work for a playdate?", timestamp: Date(), isFromCurrentUser: false)
        ]
    }
    
    private func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = MessagePreview(
            id: UUID().uuidString,
            text: newMessageText,
            timestamp: Date(),
            isFromCurrentUser: true
        )
        
        messages.append(newMessage)
        newMessageText = ""
    }
    
    private func displayUserCard() {
        withAnimation {
            showUserCard = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    userCardOffset = 0
                }
            }
        }
    }
    
    private func hideUserCard() {
        withAnimation {
            userCardOffset = 400
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showUserCard = false
            }
        }
    }
}

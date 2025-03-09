import SwiftUI
import CoreData

struct MessagesView: View {
    @State private var conversations: [ConversationPreview] = []
    @State private var eventChats: [EventChatPreview] = []
    @State private var searchText = ""
    @State private var showingProfileView = false
    @State private var selectedTab = 0 // 0 = Direct, 1 = Groups
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom title with profile button
                HStack {
                    Text("Messages")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        showingProfileView = true
                    }) {
                        Image(systemName: "person")
                            .foregroundColor(Color("AppPrimaryColor"))
                            .font(.system(size: 24))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // No read receipts info banner
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color("AppPrimaryColor"))
                    
                    Text("No read receipts - parents can respond when they have time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color("AppPrimaryColor").opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Tab selector for Direct vs Group chats
                Picker("Chat Type", selection: $selectedTab) {
                    Text("Direct").tag(0)
                    Text("Event Chats").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search conversations", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                if selectedTab == 0 {
                    // Direct messages tab
                    if conversations.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "message.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color(.systemGray4))
                            
                            Text("No conversations yet")
                                .font(.headline)
                            
                            Text("Connect with parents to start chatting")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                // Navigate to home to find parents
                            }) {
                                Text("Find Parents")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color("AppPrimaryColor"))
                                    .cornerRadius(20)
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        // Direct messages list
                        List {
                            ForEach(filteredConversations) { conversation in
                                NavigationLink {
                                    ChatView(conversation: conversation)
                                } label: {
                                    ConversationRow(conversation: conversation)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                } else {
                    // Event chats tab
                    if eventChats.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            Image(systemName: "bubble.left.and.bubble.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color(.systemGray4))
                            
                            Text("No event chats")
                                .font(.headline)
                            
                            Text("Join events to participate in group chats")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: EventsView()) {
                                Text("Browse Events")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color("AppPrimaryColor"))
                                    .cornerRadius(20)
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        // Event chats list
                        List {
                            ForEach(filteredEventChats) { eventChat in
                                NavigationLink {
                                    GroupChat(eventId: eventChat.eventId, eventTitle: eventChat.eventTitle)
                                } label: {
                                    EventChatRow(eventChat: eventChat)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .onAppear {
                loadMockConversations()
                loadUserEventChats()
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
            }
        }
    }
    
    // Apply search filter to direct conversations
    var filteredConversations: [ConversationPreview] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter {
                $0.participantName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Apply search filter to event chats
    var filteredEventChats: [EventChatPreview] {
        if searchText.isEmpty {
            return eventChats
        } else {
            return eventChats.filter {
                $0.eventTitle.localizedCaseInsensitiveContains(searchText) ||
                $0.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadMockConversations() {
        conversations = [
            ConversationPreview(
                id: "1",
                participantName: "Sarah Johnson",
                lastMessage: "Would Saturday afternoon work for a playdate?",
                timestamp: Date().addingTimeInterval(-3600),
                unread: true
            ),
            ConversationPreview(
                id: "2",
                participantName: "Mike Thompson",
                lastMessage: "Thanks for the dinosaur printables!",
                timestamp: Date().addingTimeInterval(-86400),
                unread: false
            ),
            ConversationPreview(
                id: "3",
                participantName: "Emma Roberts",
                lastMessage: "Are you going to the library event?",
                timestamp: Date().addingTimeInterval(-172800),
                unread: false
            )
        ]
    }
    
    private func loadUserEventChats() {
        // Check UserDefaults for events the user has joined
        let userEventChats = UserDefaults.standard.dictionary(forKey: "UserEventChats") as? [String: Bool] ?? [:]
        let eventChatUnread = UserDefaults.standard.dictionary(forKey: "EventChatUnread") as? [String: Int] ?? [:]
        let eventChatsLastMessage = UserDefaults.standard.dictionary(forKey: "EventChatsLastMessage") as? [String: String] ?? [:]
        let eventChatsTimestamp = UserDefaults.standard.dictionary(forKey: "EventChatsTimestamp") as? [String: Double] ?? [:]
        
        // For demo purposes, create some mock event chats
        let mockEvents = [
            ("1", "Storytime at Library"),
            ("2", "Park Playdate"),
            ("3", "Kids Art Class"),
            ("4", "Family Movie Night"),
            ("5", "Swimming Lessons")
        ]
        
        var chats: [EventChatPreview] = []
        
        for (eventId, eventTitle) in mockEvents {
            // Check if user has joined this event's chat or if we should create a mock entry
            if userEventChats[eventId] == true || (eventId == "1" || eventId == "2") {
                // If we don't have UserDefaults data for this chat yet, set some defaults
                if userEventChats[eventId] != true {
                    // Mark this event as joined
                    var updatedChats = userEventChats
                    updatedChats[eventId] = true
                    UserDefaults.standard.set(updatedChats, forKey: "UserEventChats")
                }
                
                // Get or set unread count
                let unreadCount = eventChatUnread[eventId] ?? Int.random(in: 0...5)
                
                // Get or set last message
                let lastMessage = eventChatsLastMessage[eventId] ?? getRandomLastMessage()
                
                // Get or set timestamp
                let timestamp: Date
                if let storedTimestamp = eventChatsTimestamp[eventId] {
                    timestamp = Date(timeIntervalSince1970: storedTimestamp)
                } else {
                    timestamp = Date().addingTimeInterval(Double(-3600 * Int.random(in: 1...72)))
                    
                    // Save the generated timestamp
                    var updatedTimestamps = eventChatsTimestamp
                    updatedTimestamps[eventId] = timestamp.timeIntervalSince1970
                    UserDefaults.standard.set(updatedTimestamps, forKey: "EventChatsTimestamp")
                }
                
                chats.append(EventChatPreview(
                    eventId: eventId,
                    eventTitle: eventTitle,
                    lastMessage: lastMessage,
                    participantCount: Int.random(in: 5...20),
                    timestamp: timestamp,
                    unreadCount: unreadCount
                ))
            }
        }
        
        // Sort chats by timestamp, most recent first
        eventChats = chats.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func getRandomLastMessage() -> String {
        let messages = [
            "Is anyone bringing snacks to the event?",
            "What time should we arrive?",
            "Looking forward to seeing everyone!",
            "Can someone recommend parking nearby?",
            "My kids are so excited for this!",
            "Does anyone know if it's indoors or outdoors?"
        ]
        return messages.randomElement() ?? "New message"
    }
}

// New model for event chats
struct EventChatPreview: Identifiable {
    let id = UUID().uuidString
    let eventId: String
    let eventTitle: String
    let lastMessage: String
    let participantCount: Int
    let timestamp: Date
    let unreadCount: Int
}

// Row for displaying event chats
struct EventChatRow: View {
    let eventChat: EventChatPreview
    
    var body: some View {
        HStack(spacing: 12) {
            // Event chat icon
            ZStack {
                Circle()
                    .fill(Color("AppPrimaryColor").opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("👪")
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(eventChat.eventTitle)
                        .font(.headline)
                        .fontWeight(eventChat.unreadCount > 0 ? .bold : .regular)
                    
                    // Group indicator with participant count
                    Text("(\(eventChat.participantCount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(eventChat.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(eventChat.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(eventChat.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if eventChat.unreadCount > 0 {
                        Text("\(eventChat.unreadCount)")
                            .font(.caption)
                            .padding(6)
                            .background(Color("AppPrimaryColor"))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
    }
}

struct ConversationPreview: Identifiable {
    let id: String
    let participantName: String
    let lastMessage: String
    let timestamp: Date
    let unread: Bool
}

struct ConversationRow: View {
    let conversation: ConversationPreview
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color("AppPrimaryColor").opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text("👤")
                    .font(.title)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.participantName)
                        .font(.headline)
                        .fontWeight(conversation.unread ? .bold : .regular)
                    
                    Spacer()
                    
                    Text(formatDate(conversation.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(conversation.unread ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yy"
            return formatter.string(from: date)
        }
    }
}

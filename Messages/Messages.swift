import SwiftUI
import CoreData

struct MessagesView: View {
    @State private var conversations: [ConversationPreview] = []
    @State private var eventChats: [EventChatPreview] = []
    @State private var playdateChats: [EventChatPreview] = [] // Added playdate chats
    @State private var searchText = ""
    @State private var showingProfileView = false
    @State private var selectedTab = 0 // 0 = Direct, 1 = Groups, 2 = Playdates (new)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search conversations", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Tab selector for Direct, Event, and Playdate chats
                Picker("Chat Type", selection: $selectedTab) {
                    Text("Direct").tag(0)
                    Text("Event Chats").tag(1)
                    Text("Playdate Chats").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if selectedTab == 0 {
                    // Direct messages tab
                    if conversations.isEmpty {
                        // Empty state for direct messages
                        EmptyStateView(
                            imageName: "message.circle",
                            title: "No conversations yet",
                            description: "Connect with parents to start chatting",
                            buttonText: "Find Parents"
                        )
                    } else {
                        // Direct messages list
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredConversations) { conversation in
                                    NavigationLink {
                                        ChatView(conversation: conversation)
                                    } label: {
                                        ConversationRow(conversation: conversation)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                } else if selectedTab == 1 {
                    // Event chats tab
                    if eventChats.isEmpty {
                        // Empty state for event chats with navigation destination
                        EmptyStateViewWithNavigation(
                            imageName: "bubble.left.and.bubble.right",
                            title: "No event chats",
                            description: "Join events to participate in group chats",
                            buttonText: "Browse Events",
                            destination: EventsView()
                        )
                    } else {
                        // Event chats list
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredEventChats) { eventChat in
                                    NavigationLink {
                                        GroupChat(eventId: eventChat.eventId, eventTitle: eventChat.eventTitle)
                                    } label: {
                                        EventChatRow(eventChat: eventChat)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    // Playdate chats tab
                    if playdateChats.isEmpty {
                        // Empty state for playdate chats with navigation destination
                        EmptyStateViewWithNavigation(
                            imageName: "bubble.left.and.bubble.right",
                            title: "No playdate chats",
                            description: "Join playdates to participate in group chats",
                            buttonText: "Browse Playdates",
                            destination: Playdates()
                        )
                    } else {
                        // Playdate chats list
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                ForEach(filteredPlaydateChats) { playdateChat in
                                    NavigationLink {
                                        GroupChat(eventId: playdateChat.eventId, eventTitle: playdateChat.eventTitle)
                                    } label: {
                                        EventChatRow(eventChat: playdateChat)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .onAppear {
                loadMockConversations()
                loadUserEventChats()
                loadUserPlaydateChats()
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
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
    
    // Apply search filter to playdate chats
    var filteredPlaydateChats: [EventChatPreview] {
        if searchText.isEmpty {
            return playdateChats
        } else {
            return playdateChats.filter {
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
    
    private func loadUserPlaydateChats() {
        // Check UserDefaults for playdates the user has joined
        let userPlaydateChats = UserDefaults.standard.dictionary(forKey: "UserPlaydateChats") as? [String: Bool] ?? [:]
        let playdateChatUnread = UserDefaults.standard.dictionary(forKey: "PlaydateChatUnread") as? [String: Int] ?? [:]
        let playdateChatsLastMessage = UserDefaults.standard.dictionary(forKey: "PlaydateChatsLastMessage") as? [String: String] ?? [:]
        let playdateChatsTimestamp = UserDefaults.standard.dictionary(forKey: "PlaydateChatsTimestamp") as? [String: Double] ?? [:]
        
        // For demo purposes, create some mock playdate chats
        let mockPlaydates = [
            ("101", "Playground Meetup"),
            ("202", "Swimming Pool Fun"),
            ("303", "Library Play Corner"),
            ("404", "Nature Walk & Play"),
            ("505", "Indoor Playground Meetup")
        ]
        
        var chats: [EventChatPreview] = []
        
        for (playdateId, playdateTitle) in mockPlaydates {
            // Check if user has joined this playdate's chat or if we should create a mock entry
            if userPlaydateChats[playdateId] == true || (playdateId == "101" || playdateId == "202") {
                // If we don't have UserDefaults data for this chat yet, set some defaults
                if userPlaydateChats[playdateId] != true {
                    // Mark this playdate as joined
                    var updatedChats = userPlaydateChats
                    updatedChats[playdateId] = true
                    UserDefaults.standard.set(updatedChats, forKey: "UserPlaydateChats")
                }
                
                // Get or set unread count
                let unreadCount = playdateChatUnread[playdateId] ?? Int.random(in: 0...5)
                
                // Get or set last message
                let lastMessage = playdateChatsLastMessage[playdateId] ?? getRandomLastMessage()
                
                // Get or set timestamp
                let timestamp: Date
                if let storedTimestamp = playdateChatsTimestamp[playdateId] {
                    timestamp = Date(timeIntervalSince1970: storedTimestamp)
                } else {
                    timestamp = Date().addingTimeInterval(Double(-3600 * Int.random(in: 1...72)))
                    
                    // Save the generated timestamp
                    var updatedTimestamps = playdateChatsTimestamp
                    updatedTimestamps[playdateId] = timestamp.timeIntervalSince1970
                    UserDefaults.standard.set(updatedTimestamps, forKey: "PlaydateChatsTimestamp")
                }
                
                chats.append(EventChatPreview(
                    eventId: playdateId,
                    eventTitle: playdateTitle,
                    lastMessage: lastMessage,
                    participantCount: Int.random(in: 3...12),
                    timestamp: timestamp,
                    unreadCount: unreadCount
                ))
            }
        }
        
        // Sort chats by timestamp, most recent first
        playdateChats = chats.sorted { $0.timestamp > $1.timestamp }
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

// Non-generic empty state view with action closure
struct EmptyStateView: View {
    let imageName: String
    let title: String
    let description: String
    let buttonText: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(Color(.systemGray4))
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(buttonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color("AppPrimaryColor"))
                    .cornerRadius(20)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Separate non-generic view for empty state with navigation
struct EmptyStateViewWithNavigation<Destination: View>: View {
    let imageName: String
    let title: String
    let description: String
    let buttonText: String
    let destination: Destination
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(Color(.systemGray4))
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: destination) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(buttonText)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color("AppPrimaryColor"))
                .cornerRadius(20)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
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

// Row for displaying event chats - improved visual design
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
            
            VStack(alignment: .leading, spacing: 5) {
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
                
                Text(eventChat.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(eventChat.unreadCount > 0 ? .primary : .secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Adding the unread counter to a new line to avoid crowding
                if eventChat.unreadCount > 0 {
                    HStack {
                        Spacer()
                        Text("\(eventChat.unreadCount) new")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("AppPrimaryColor"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
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

// Improved conversation row
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
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(conversation.participantName)
                        .font(.headline)
                        .fontWeight(conversation.unread ? .bold : .regular)
                    
                    Spacer()
                    
                    Text(formatDate(conversation.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(conversation.unread ? .primary : .secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unread {
                        Circle()
                            .fill(Color("AppPrimaryColor"))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
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

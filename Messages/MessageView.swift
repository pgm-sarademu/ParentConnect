import SwiftUI
import CoreData

struct MessagesView: View {
    @State private var conversations: [ConversationPreview] = []
    @State private var searchText = ""
    @State private var showingProfileView = false
    
    var body: some View {
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
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color("AppPrimaryColor"))
                        .font(.system(size: 28))
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
                List {
                    ForEach(conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadMockConversations()
        }
        .sheet(isPresented: $showingProfileView) {
            ProfileView()
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

import SwiftUI
import MapKit

struct PlaydateDetail: View {
    let playdate: PlaydatePreview
    @Environment(\.presentationMode) var presentationMode
    @State private var isAttending = false
    @State private var showingShareSheet = false
    @State private var showingAttendees = false
    @State private var showingChatView = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    
    // Mock data
    let attendeeCount = Int.random(in: 2...8)
    @State private var unreadMessages = Int.random(in: 0...5)
    
    // Sample description
    let playdateDescription = "Join us for a casual playdate at the park! Kids can play on the playground equipment while parents chat and get to know each other. Feel free to bring snacks and drinks. All parents should stay with their children during the playdate. Looking forward to meeting everyone!"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Playdate image/banner
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    Text("🧩")
                        .font(.system(size: 80))
                    
                    // Date badge overlay
                    HStack(spacing: 4) {
                        VStack(spacing: 0) {
                            Text(formatDay(playdate.date))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(formatDayNumber(playdate.date))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color("AppPrimaryColor"))
                        .cornerRadius(8)
                    }
                    .padding(12)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Title and info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(playdate.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatFullDate(playdate.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(formatTime(playdate.date))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text(playdate.location)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Age range: \(playdate.ageRange)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color("AppPrimaryColor"))
                            
                            Text("Host: \(playdate.hostName)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Attendee count
                    HStack {
                        Image(systemName: "person.3")
                            .foregroundColor(Color("AppPrimaryColor"))
                        
                        Text("\(attendeeCount) \(attendeeCount == 1 ? "parent" : "parents") attending")
                            .foregroundColor(.secondary)
                    }
                    
                    // Playdate details
                    Text("Playdate Details")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(playdateDescription)
                        .foregroundColor(.secondary)
                    
                    // Attendance buttons
                    HStack {
                        Button(action: {
                            isAttending.toggle()
                            
                            // If the user is now attending, add them to the playdate chat
                            if isAttending {
                                addUserToPlaydateChat()
                            }
                        }) {
                            HStack {
                                Image(systemName: isAttending ? "checkmark.circle.fill" : "circle")
                                Text(isAttending ? "Attending" : "Attend")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(isAttending ? Color("AppPrimaryColor") : Color(.systemGray6))
                            .foregroundColor(isAttending ? .white : .primary)
                            .cornerRadius(25)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(25)
                        }
                    }
                    .padding(.top, 10)
                    
                    // View participants button
                    Button(action: {
                        showingAttendees = true
                    }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            Text("View Participants")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.top, 5)
                    }
                    
                    // Event chat button
                    if isAttending {
                        Button(action: {
                            showingChatView = true
                        }) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                Text("Group Chat")
                                    .foregroundColor(Color("AppPrimaryColor"))
                                Spacer()
                                
                                if unreadMessages > 0 {
                                    Text("\(unreadMessages) new")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color("AppPrimaryColor"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color("AppPrimaryColor").opacity(0.1))
                            .cornerRadius(10)
                            .padding(.top, 5)
                        }
                    }
                    
                    Divider()
                    
                    // Map preview
                    Text("Location")
                        .font(.headline)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .cornerRadius(12)
                        
                        Text("📍 \(playdate.location)")
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(8)
                    }
                    
                    // Organizer info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Hosted by")
                            .font(.headline)
                            .padding(.top, 10)
                        
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("👤")
                                        .font(.system(size: 20))
                                )
                            
                            VStack(alignment: .leading) {
                                Text(playdate.hostName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("Parent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Message host action
                            }) {
                                Text("Message")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color("AppPrimaryColor"))
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Toast message overlay
            if showingToast {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(toastMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color("AppPrimaryColor").opacity(0.9))
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(Color("AppPrimaryColor"))
            }
        )
        .onAppear(perform: checkAttendanceStatus)
        .sheet(isPresented: $showingChatView) {
            NavigationView {
                GroupChat(eventId: playdate.id, eventTitle: playdate.title)
            }
        }
    }
    
    private func checkAttendanceStatus() {
        // This would load from UserDefaults or Core Data in a real app
        let attendingPlaydates = UserDefaults.standard.dictionary(forKey: "UserAttendingPlaydates") as? [String: Bool] ?? [:]
        isAttending = attendingPlaydates[playdate.id] == true
    }
    
    private func addUserToPlaydateChat() {
        // Update attendance status
        var attendingPlaydates = UserDefaults.standard.dictionary(forKey: "UserAttendingPlaydates") as? [String: Bool] ?? [:]
        attendingPlaydates[playdate.id] = true
        UserDefaults.standard.set(attendingPlaydates, forKey: "UserAttendingPlaydates")
        
        // Create an entry in UserDefaults to track playdate chats
        var playdateChats = UserDefaults.standard.dictionary(forKey: "UserPlaydateChats") as? [String: Bool] ?? [:]
        playdateChats[playdate.id] = true
        UserDefaults.standard.set(playdateChats, forKey: "UserPlaydateChats")
        
        // Update unread count to 0 since the user just joined
        var playdateChatUnread = UserDefaults.standard.dictionary(forKey: "PlaydateChatUnread") as? [String: Int] ?? [:]
        playdateChatUnread[playdate.id] = 0
        UserDefaults.standard.set(playdateChatUnread, forKey: "PlaydateChatUnread")
        
        // Show toast message
        toastMessage = "Added to playdate chat. Check the Messages tab to participate!"
        withAnimation {
            showingToast = true
        }
        
        // Hide the toast after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation {
                showingToast = false
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// Preview provider for SwiftUI canvas
struct PlaydateDetail_Previews: PreviewProvider {
    static var previews: some View {
        let mockPlaydate = PlaydatePreview(
            id: "101",
            title: "Park Playdate",
            date: Date().addingTimeInterval(172800), // 2 days from now
            location: "Sunshine Park",
            ageRange: "3-5 years",
            hostName: "Sarah Johnson"
        )
        
        return NavigationView {
            PlaydateDetail(playdate: mockPlaydate)
        }
    }
}

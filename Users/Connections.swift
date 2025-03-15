import SwiftUI

struct ConnectionUser: Identifiable {
    let id: String
    let name: String
    let location: String
    let childrenInfo: String
    let isConnected: Bool
    let lastActivityDate: Date?
}

struct Connections: View {
    @State private var searchText = ""
    @State private var connections: [ConnectionUser] = []
    @State private var pendingConnections: [ConnectionUser] = []
    @State private var isLoading = true
    @State private var selectedTab = 0 // 0 = Connected, 1 = Pending
    
    // User card state
    @State private var showUserCard = false
    @State private var userCardOffset: CGFloat = 400
    @State private var selectedUser: ParticipantInfo?
    
    var filteredConnections: [ConnectionUser] {
        if searchText.isEmpty {
            return connections
        } else {
            return connections.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var filteredPendingConnections: [ConnectionUser] {
        if searchText.isEmpty {
            return pendingConnections
        } else {
            return pendingConnections.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom title
                HStack {
                    Text("Connections")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search connections", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Tab selector
                Picker("Connection Type", selection: $selectedTab) {
                    Text("Connected").tag(0)
                    Text("Pending").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 10)
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading connections...")
                    Spacer()
                } else if selectedTab == 0 && filteredConnections.isEmpty {
                    // Empty state for connections
                    emptyConnectionsView
                } else if selectedTab == 1 && filteredPendingConnections.isEmpty {
                    // Empty state for pending connections
                    emptyPendingView
                } else {
                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Connected parents list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredConnections) { connection in
                                    ConnectionRow(
                                        connection: connection,
                                        onTap: {
                                            displayUserCardFor(connection)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    } else {
                        // Pending connections list
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPendingConnections) { connection in
                                    PendingConnectionRow(
                                        connection: connection,
                                        onAccept: { acceptConnection(connection) },
                                        onDecline: { declineConnection(connection) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            
            // Overlay for user card
            if showUserCard && selectedUser != nil {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideUserCard()
                    }
                
                UserCard(
                    user: selectedUser!,
                    isPresented: $showUserCard,
                    onConnectTapped: { isConnected in
                        // Handle disconnection if needed
                        if !isConnected {
                            handleDisconnect()
                        }
                    }
                )
                .offset(y: userCardOffset)
                .animation(.spring(dampingFraction: 0.7), value: userCardOffset)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConnections()
        }
    }
    
    // MARK: - Empty States
    
    var emptyConnectionsView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.2.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(Color(.systemGray4))
            
            Text("No connections yet")
                .font(.headline)
            
            Text("Connect with parents you meet at events and playdates")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: EventsView()) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Browse Events")
                }
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
    }
    
    var emptyPendingView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.clock")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(Color(.systemGray4))
            
            Text("No pending requests")
                .font(.headline)
            
            Text("When parents want to connect with you, they'll appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadConnections() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // In a real app, fetch from Core Data or API
            self.connections = [
                ConnectionUser(
                    id: "1",
                    name: "Sarah Johnson",
                    location: "Brooklyn, NY",
                    childrenInfo: "2 kids (4, 6)",
                    isConnected: true,
                    lastActivityDate: Date().addingTimeInterval(-86400) // 1 day ago
                ),
                ConnectionUser(
                    id: "2",
                    name: "Mike Thompson",
                    location: "Queens, NY",
                    childrenInfo: "1 kid (3)",
                    isConnected: true,
                    lastActivityDate: Date().addingTimeInterval(-172800) // 2 days ago
                ),
                ConnectionUser(
                    id: "3",
                    name: "Emma Roberts",
                    location: "Manhattan, NY",
                    childrenInfo: "3 kids (2, 5, 7)",
                    isConnected: true,
                    lastActivityDate: Date().addingTimeInterval(-259200) // 3 days ago
                ),
                ConnectionUser(
                    id: "4",
                    name: "David Wilson",
                    location: "Staten Island, NY",
                    childrenInfo: "2 kids (4, 8)",
                    isConnected: true,
                    lastActivityDate: Date().addingTimeInterval(-432000) // 5 days ago
                ),
                ConnectionUser(
                    id: "5",
                    name: "Jennifer Brown",
                    location: "Bronx, NY",
                    childrenInfo: "1 kid (5)",
                    isConnected: true,
                    lastActivityDate: Date().addingTimeInterval(-604800) // 7 days ago
                )
            ]
            
            self.pendingConnections = [
                ConnectionUser(
                    id: "6",
                    name: "Michael Scott",
                    location: "Manhattan, NY",
                    childrenInfo: "2 kids (4, 7)",
                    isConnected: false,
                    lastActivityDate: Date().addingTimeInterval(-43200) // 12 hours ago
                ),
                ConnectionUser(
                    id: "7",
                    name: "Jessica Martinez",
                    location: "Brooklyn, NY",
                    childrenInfo: "1 kid (2)",
                    isConnected: false,
                    lastActivityDate: Date().addingTimeInterval(-86400) // 1 day ago
                )
            ]
            
            self.isLoading = false
        }
    }
    
    private func displayUserCardFor(_ connection: ConnectionUser) {
        // Create child objects from the connection info string
        var children: [ChildInfo] = []
        
        // Parse "2 kids (4, 6)" format
        if let agesString = connection.childrenInfo.split(separator: "(").last?.split(separator: ")").first {
            let ages = agesString.split(separator: ",").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
            
            for (index, age) in ages.enumerated() {
                let name = ["Emma", "Noah", "Olivia", "Liam", "Ava", "Sophia", "Jackson"][index % 7]
                children.append(ChildInfo(id: UUID().uuidString, name: name, age: age))
            }
        }
        
        // Create the participant info
        selectedUser = ParticipantInfo(
            id: connection.id,
            name: connection.name,
            location: connection.location,
            bio: "Parent interested in community activities and playdates.",
            children: children
        )
        
        // Show the user card with animation
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
                selectedUser = nil
            }
        }
    }
    
    private func handleDisconnect() {
        // In a real app, this would update the connection status in your database
        guard let user = selectedUser else { return }
        
        // Remove from connections list
        connections.removeAll { $0.id == user.id }
    }
    
    private func acceptConnection(_ connection: ConnectionUser) {
        // In a real app, this would accept the connection in your database
        withAnimation {
            // Remove from pending
            pendingConnections.removeAll { $0.id == connection.id }
            
            // Add to connections
            let newConnection = ConnectionUser(
                id: connection.id,
                name: connection.name,
                location: connection.location,
                childrenInfo: connection.childrenInfo,
                isConnected: true,
                lastActivityDate: Date()
            )
            
            connections.append(newConnection)
        }
    }
    
    private func declineConnection(_ connection: ConnectionUser) {
        // In a real app, this would decline the connection in your database
        withAnimation {
            pendingConnections.removeAll { $0.id == connection.id }
        }
    }
}

// MARK: - Row Components

struct ConnectionRow: View {
    let connection: ConnectionUser
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color("AppPrimaryColor").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text("👤")
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                        
                        Text(connection.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                        
                        Text(connection.childrenInfo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Last activity
                if let lastActivity = connection.lastActivityDate {
                    VStack(alignment: .trailing) {
                        Text("Last active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(timeAgo(from: lastActivity))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}

struct PendingConnectionRow: View {
    let connection: ConnectionUser
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color("AppPrimaryColor").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text("👤")
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.name)
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                        
                        Text(connection.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                        
                        Text(connection.childrenInfo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Request info
            Text("Wants to connect with you")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 62) // Align with the text above
            
            // Accept/Decline buttons
            HStack {
                Spacer()
                
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AppPrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                Button(action: onDecline) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(20)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

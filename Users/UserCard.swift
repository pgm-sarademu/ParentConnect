import SwiftUI

// Models for user and child information
struct ParticipantInfo {
    let id: String
    let name: String
    let location: String
    let bio: String
    let children: [ChildInfo]
}

struct ChildInfo: Identifiable {
    let id: String
    let name: String
    let age: Int
}

struct UserCard: View {
    let user: ParticipantInfo
    @State private var isConnected = false
    @Binding var isPresented: Bool
    var onConnectTapped: ((Bool) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
                .padding(.bottom, 5)
            }
            
            HStack(spacing: 15) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color("AppPrimaryColor").opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    Text("👤")
                        .font(.system(size: 35))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Color("AppPrimaryColor"))
                            .font(.caption)
                        
                        Text(user.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Bio if provided
            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            
            // Children info
            VStack(alignment: .leading, spacing: 8) {
                Text("Children")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 10) {
                    ForEach(user.children, id: \.id) { child in
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(Color("AppPrimaryColor").opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Text(child.age < 3 ? "👶" : "🧒")
                            }
                            
                            VStack(spacing: 2) {
                                Text(child.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text("\(child.age) yrs")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 60)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Connect button
            Button(action: {
                isConnected.toggle()
                onConnectTapped?(isConnected)
            }) {
                HStack {
                    Image(systemName: isConnected ? "link.circle.fill" : "link.circle")
                    Text(isConnected ? "Connected" : "Connect")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isConnected ? Color.gray.opacity(0.2) : Color("AppPrimaryColor"))
                .foregroundColor(isConnected ? .primary : .white)
                .cornerRadius(10)
                .animation(.easeInOut, value: isConnected)
            }
            .disabled(isConnected)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding()
    }
}

#Preview {
    UserCard(
        user: ParticipantInfo(
            id: "123",
            name: "Sarah Johnson",
            location: "Brooklyn, NY",
            bio: "Mom of two. Love outdoor activities and arts & crafts.",
            children: [
                ChildInfo(id: "1", name: "Emma", age: 4),
                ChildInfo(id: "2", name: "Noah", age: 2)
            ]
        ),
        isPresented: .constant(true)
    )
}

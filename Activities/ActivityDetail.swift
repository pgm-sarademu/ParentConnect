import SwiftUI

struct ActivityDetail: View {
    let activity: ActivityItem
    @State private var isSaved = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    Text(activityEmoji(for: activity.type))
                        .font(.system(size: 80))
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    // Title and save button
                    HStack {
                        Text(activity.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            isSaved.toggle()
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundColor(Color("AppPrimaryColor"))
                        }
                    }
                    
                    // Category tag
                    Text(activity.type)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("AppPrimaryColor").opacity(0.2))
                        .foregroundColor(Color("AppPrimaryColor"))
                        .cornerRadius(5)
                    
                    Divider()
                    
                    // Description
                    Text("About this activity")
                        .font(.headline)
                    
                    Text(activity.description)
                        .foregroundColor(.secondary)
                    
                    // Mock content area
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Preview")
                            .font(.headline)
                            .padding(.top)
                        
                        // Preview images/placeholders
                        TabView {
                            ForEach(1...3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Text(activityEmoji(for: activity.type))
                                            .font(.system(size: 50))
                                    )
                            }
                        }
                        .frame(height: 250)
                        .tabViewStyle(PageTabViewStyle())
                        .cornerRadius(12)
                        
                        // Download/share buttons
                        HStack {
                            Button(action: {
                                // Download action
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.doc")
                                    Text("Download")
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color("AppPrimaryColor"))
                                .foregroundColor(.white)
                                .cornerRadius(25)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Share action
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(25)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func activityEmoji(for type: String) -> String {
        switch type {
        case "Printables": return "📄"
        case "Guides": return "📚"
        case "Crafts": return "✂️"
        case "Educational": return "🧠"
        case "Outdoor": return "🌳"
        default: return "🎯"
        }
    }
}

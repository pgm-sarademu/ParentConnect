import SwiftUI

struct ActivitiesView: View {
    @State private var activities: [ActivityItem] = []
    @State private var searchText = ""
    @State private var selectedCategory: String? = "All"
    
    let categories = ["All", "Printables", "Guides", "Crafts", "Educational", "Outdoor"]
    
    var filteredActivities: [ActivityItem] {
        var filtered = activities
        
        if let category = selectedCategory, category != "All" {
            filtered = filtered.filter { $0.type == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedCategory == category ?
                                        Color("AppPrimaryColor") :
                                        Color(.systemGray6)
                                    )
                                    .foregroundColor(
                                        selectedCategory == category ?
                                        .white :
                                        .primary
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Activities grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        ForEach(filteredActivities) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                ActivityCard(activity: activity)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Activities")
            .searchable(text: $searchText, prompt: "Search activities")
            .onAppear {
                loadMockActivities()
            }
        }
    }
    
    private func loadMockActivities() {
        activities = [
            ActivityItem(id: "1", title: "Dinosaur Coloring Pages", type: "Printables", description: "A collection of dinosaur-themed coloring pages for kids of all ages."),
            ActivityItem(id: "2", title: "Sensory Play Ideas", type: "Guides", description: "10 easy sensory play activities you can set up with items from around your home."),
            ActivityItem(id: "3", title: "Letters Tracing Worksheet", type: "Printables", description: "Help your child practice handwriting with these alphabet tracing sheets."),
            ActivityItem(id: "4", title: "DIY Bird Feeder", type: "Crafts", description: "Create a simple bird feeder using a plastic bottle and some bird seed."),
            ActivityItem(id: "5", title: "Counting Games", type: "Educational", description: "Fun games to help young children learn counting and basic math."),
            ActivityItem(id: "6", title: "Scavenger Hunt", type: "Outdoor", description: "Printable scavenger hunt lists for different ages and environments."),
            ActivityItem(id: "7", title: "Animal Flashcards", type: "Printables", description: "Printable animal flashcards with names and facts."),
            ActivityItem(id: "8", title: "Paper Plate Crafts", type: "Crafts", description: "Five creative crafts using paper plates and basic craft supplies.")
        ]
    }
}

struct ActivityItem: Identifiable {
    let id: String
    let title: String
    let type: String
    let description: String
}

struct ActivityCard: View {
    let activity: ActivityItem
    
    var body: some View {
        VStack(alignment: .leading) {
            // Activity image placeholder
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(4/3, contentMode: .fit)
                    .cornerRadius(8)
                
                Text(activityEmoji(for: activity.type))
                    .font(.system(size: 40))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(activity.type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AppPrimaryColor").opacity(0.2))
                    .foregroundColor(Color("AppPrimaryColor"))
                    .cornerRadius(4)
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

struct ActivityDetailView: View {
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

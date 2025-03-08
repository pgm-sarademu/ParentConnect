import SwiftUI

struct Activities: View {
    @State private var activities: [ActivityItem] = []
    @State private var searchText = ""
    @State private var selectedCategory: String? = "All"
    @State private var showingProfileView = false
    
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
                // Custom title with profile button
                HStack {
                    Text("Activities")
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
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search activities", text: $searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Activities grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                        ForEach(filteredActivities) { activity in
                            NavigationLink {
                                ActivityDetail(activity: activity)
                            } label: {
                                ActivityCard(activity: activity)
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                loadMockActivities()
            }
            .sheet(isPresented: $showingProfileView) {
                Profile()
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

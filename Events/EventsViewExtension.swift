import SwiftUI

// Extensions for EventsView to integrate the create event functionality
extension EventsView {
    
    // Updated toolbar with Create Event functionality
    func updatedToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showingCreateEventSheet = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(Color("AppPrimaryColor"))
            }
        }
    }
    
    // Updated sorting for events to respect privacy settings
    func getFilteredEvents(_ events: [EventPreview], forCurrentUser userId: String = "currentUserId") -> [EventPreview] {
        var filtered = events
        
        // Filter by selected filter (Today, This Week, etc.)
        if let filter = selectedFilter, filter != "All" {
            switch filter {
            case "Today":
                let today = Calendar.current.startOfDay(for: Date())
                filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            case "This Week":
                let today = Calendar.current.startOfDay(for: Date())
                guard let oneWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: today) else {
                    return filtered
                }
                filtered = filtered.filter { $0.date >= today && $0.date <= oneWeekLater }
            case "Kid-Friendly":
                // This would filter for age-appropriate events
                // For demo purposes we keep all events
                break
            case "Free":
                // Filter for free events
                // Implementation would depend on having the paid status in EventPreview
                break
            case "My Events":
                // Show only events created by current user
                filtered = filtered.filter { $0.createdBy == userId }
            default:
                break
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // In a real app, you would also filter by privacy settings here
        // For example, only show Public events, Friends Only events where the user is a friend, etc.
        
        return filtered.sorted { $0.date < $1.date }
    }
}

// Extended EventPreview with privacy fields
extension EventPreview {
    // These would be the actual properties in a real implementation
    var visibilityLevel: String { return "Public" } // Default placeholder
    var createdBy: String { return "defaultUserId" } // Default placeholder
    var participantIds: [String] { return [] } // Default placeholder
    var invitedIds: [String] { return [] } // Default placeholder
    
    // Helper to determine if the current user has access to this event
    func isVisibleToUser(userId: String, userFriendIds: [String]) -> Bool {
        // Creator always has access
        if createdBy == userId {
            return true
        }
        
        // Check visibility level
        switch visibilityLevel {
        case "Public":
            return true
        case "Friends Only":
            return userFriendIds.contains(createdBy)
        case "Invite Only":
            return invitedIds.contains(userId)
        case "Private":
            return false
        default:
            return false
        }
    }
}

// Core Data helper extension
extension EventsView {
    // Method to load events that properly respects privacy settings
    func loadEventsFromCoreData() {
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        
        do {
            // Fetch all events
            let coreDataEvents = try viewContext.fetch(fetchRequest)
            
            // Transform to EventPreview objects
            let allEvents = coreDataEvents.map { event -> EventPreview in
                let preview = EventPreview(
                    id: event.id ?? UUID().uuidString,
                    title: event.title ?? "",
                    date: event.date ?? Date(),
                    location: event.location ?? "",
                    createdBy: event.createdBy ?? ""
                )
                return preview
            }
            
            // Get current user's friends
            let userFriendIds = fetchUserFriends()
            
            // Filter based on privacy settings
            events = allEvents.filter { event in
                return event.isVisibleToUser(userId: "currentUserId", userFriendIds: userFriendIds)
            }
        } catch {
            print("Error fetching events: \(error)")
        }
    }
    
    // Fetch the current user's friends
    private func fetchUserFriends() -> [String] {
        let fetchRequest: NSFetchRequest<Friend> = Friend.fetchRequest()
        // Only include confirmed friends
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND status == %@", "currentUserId", "confirmed")
        
        do {
            let friendRelationships = try viewContext.fetch(fetchRequest)
            return friendRelationships.compactMap { $0.friendId }
        } catch {
            print("Error fetching friends: \(error)")
            return []
        }
    }
    
    // Method to check if user is invited to an event
    func isUserInvitedToEvent(userId: String, eventId: String) -> Bool {
        let fetchRequest: NSFetchRequest<EventParticipant> = EventParticipant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND eventId == %@", userId, eventId)
        
        do {
            let count = try viewContext.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking event invitation: \(error)")
            return false
        }
    }
}

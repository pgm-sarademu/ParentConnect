import Foundation
import CoreData

// Manages connections between users who attend the same events
class ConnectionManager {
    static let shared = ConnectionManager()
    
    private init() {}
    
    // Stores a record of who is participating in which events
    // In a real app, this would be in Core Data
    func markParticipating(eventId: String, userId: String) {
        // Get existing participants for this event
        var eventParticipants = UserDefaults.standard.dictionary(forKey: "EventParticipants") as? [String: [String]] ?? [:]
        
        // Add this user to the participants list
        var participants = eventParticipants[eventId] ?? []
        if !participants.contains(userId) {
            participants.append(userId)
        }
        eventParticipants[eventId] = participants
        
        // Save back to UserDefaults
        UserDefaults.standard.set(eventParticipants, forKey: "EventParticipants")
    }
    
    // Removes a user from participating in an event
    func unmarkParticipating(eventId: String, userId: String) {
        var eventParticipants = UserDefaults.standard.dictionary(forKey: "EventParticipants") as? [String: [String]] ?? [:]
        
        var participants = eventParticipants[eventId] ?? []
        participants.removeAll { $0 == userId }
        
        eventParticipants[eventId] = participants
        UserDefaults.standard.set(eventParticipants, forKey: "EventParticipants")
    }
    
    // Gets all user IDs participating in a specific event
    func getParticipants(eventId: String) -> [String] {
        let eventParticipants = UserDefaults.standard.dictionary(forKey: "EventParticipants") as? [String: [String]] ?? [:]
        return eventParticipants[eventId] ?? []
    }
    
    // Checks if a user is participating in an event
    func isParticipating(eventId: String, userId: String) -> Bool {
        let participants = getParticipants(eventId: eventId)
        return participants.contains(userId)
    }
    
    // Create a connection request between two users
    func requestConnection(fromUserId: String, toUserId: String) {
        // Get existing connection requests
        var connectionRequests = UserDefaults.standard.dictionary(forKey: "ConnectionRequests") as? [String: [String]] ?? [:]
        
        // Add this request to the list
        var requests = connectionRequests[toUserId] ?? []
        if !requests.contains(fromUserId) {
            requests.append(fromUserId)
        }
        connectionRequests[toUserId] = requests
        
        // Save back to UserDefaults
        UserDefaults.standard.set(connectionRequests, forKey: "ConnectionRequests")
    }
    
    // Accept a connection request
    func acceptConnection(fromUserId: String, toUserId: String) {
        // Remove the request first
        removeConnectionRequest(fromUserId: fromUserId, toUserId: toUserId)
        
        // Add to connections
        var connections = UserDefaults.standard.dictionary(forKey: "Connections") as? [String: [String]] ?? [:]
        
        // Add connection for both users (bidirectional)
        var fromConnections = connections[fromUserId] ?? []
        if !fromConnections.contains(toUserId) {
            fromConnections.append(toUserId)
        }
        connections[fromUserId] = fromConnections
        
        var toConnections = connections[toUserId] ?? []
        if !toConnections.contains(fromUserId) {
            toConnections.append(fromUserId)
        }
        connections[toUserId] = toConnections
        
        // Save back to UserDefaults
        UserDefaults.standard.set(connections, forKey: "Connections")
    }
    
    // Remove a connection request
    private func removeConnectionRequest(fromUserId: String, toUserId: String) {
        var connectionRequests = UserDefaults.standard.dictionary(forKey: "ConnectionRequests") as? [String: [String]] ?? [:]
        
        var requests = connectionRequests[toUserId] ?? []
        requests.removeAll { $0 == fromUserId }
        
        connectionRequests[toUserId] = requests
        UserDefaults.standard.set(connectionRequests, forKey: "ConnectionRequests")
    }
    
    // Check if users are connected
    func areConnected(userIdA: String, userIdB: String) -> Bool {
        let connections = UserDefaults.standard.dictionary(forKey: "Connections") as? [String: [String]] ?? [:]
        let userAConnections = connections[userIdA] ?? []
        
        return userAConnections.contains(userIdB)
    }
    
    // Get all connection requests for a user
    func getConnectionRequests(userId: String) -> [String] {
        let connectionRequests = UserDefaults.standard.dictionary(forKey: "ConnectionRequests") as? [String: [String]] ?? [:]
        return connectionRequests[userId] ?? []
    }
    
    // Get all connections for a user
    func getConnections(userId: String) -> [String] {
        let connections = UserDefaults.standard.dictionary(forKey: "Connections") as? [String: [String]] ?? [:]
        return connections[userId] ?? []
    }
}

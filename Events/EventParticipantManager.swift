import SwiftUI
import CoreData

// Class to handle event participation and invitations
class EventParticipationManager: ObservableObject {
    static let shared = EventParticipationManager()
    
    private init() {}
    
    // MARK: - Event Participation Methods
    
    // Add user as a participant to an event
    func joinEvent(eventId: String, userId: String, privacyLevel: String = "Public", context: NSManagedObjectContext) -> Bool {
        // Check if user is already a participant
        if isUserParticipant(eventId: eventId, userId: userId, context: context) {
            return false
        }
        
        // Create a new participation record
        let participant = EventParticipant(context: context)
        participant.id = UUID().uuidString
        participant.eventId = eventId
        participant.userId = userId
        participant.joinDate = Date()
        participant.privacyLevel = privacyLevel
        
        // Save context
        do {
            try context.save()
            return true
        } catch {
            print("Error joining event: \(error)")
            return false
        }
    }
    
    // Remove user as a participant from an event
    func leaveEvent(eventId: String, userId: String, context: NSManagedObjectContext) -> Bool {
        // Find the participation record
        let fetchRequest: NSFetchRequest<EventParticipant> = EventParticipant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@ AND userId == %@", eventId, userId)
        
        do {
            let participants = try context.fetch(fetchRequest)
            
            if let participant = participants.first {
                context.delete(participant)
                try context.save()
                return true
            }
            
            return false
        } catch {
            print("Error leaving event: \(error)")
            return false
        }
    }
    
    // Check if user is already a participant
    func isUserParticipant(eventId: String, userId: String, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<EventParticipant> = EventParticipant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@ AND userId == %@", eventId, userId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking event participation: \(error)")
            return false
        }
    }
    
    // MARK: - Event Invitation Methods
    
    // Send an invitation to a user
    func inviteUserToEvent(eventId: String, userId: String, inviteeId: String, context: NSManagedObjectContext) -> Bool {
        // Check if invitation already exists
        if isUserInvited(eventId: eventId, inviteeId: inviteeId, context: context) {
            return false
        }
        
        // Create a new invitation
        let invite = EventInvite(context: context)
        invite.id = UUID().uuidString
        invite.eventId = eventId
        invite.inviteeId = inviteeId
        invite.inviteDate = Date()
        invite.status = "Pending"
        
        // Save context
        do {
            try context.save()
            return true
        } catch {
            print("Error inviting user: \(error)")
            return false
        }
    }
    
    // Check if user is already invited
    func isUserInvited(eventId: String, inviteeId: String, context: NSManagedObjectContext) -> Bool {
        // In an actual implementation, you would create an EventInvite entity
        // For this example, we'll assume this method checks an existing entity
        
        // Simulated check - would be replaced with actual Core Data fetch
        return false
    }
    
    // Accept an invitation
    func acceptInvitation(inviteId: String, context: NSManagedObjectContext) -> Bool {
        // In an actual implementation, you would fetch the invitation, update its status,
        // and then add the user as a participant
        
        // Simulated process - would be replaced with actual Core Data operations
        return true
    }
    
    // Decline an invitation
    func declineInvitation(inviteId: String, context: NSManagedObjectContext) -> Bool {
        // In an actual implementation, you would fetch the invitation and update its status
        
        // Simulated process - would be replaced with actual Core Data operations
        return true
    }
    
    // MARK: - Participant Management (for event creators)
    
    // Get list of participants for an event
    func getEventParticipants(eventId: String, context: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<EventParticipant> = EventParticipant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId)
        
        do {
            let participants = try context.fetch(fetchRequest)
            return participants.compactMap { $0.userId }
        } catch {
            print("Error fetching event participants: \(error)")
            return []
        }
    }
    
    // Remove a participant from an event (by the event creator)
    func removeParticipant(eventId: String, participantId: String, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<EventParticipant> = EventParticipant.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "eventId == %@ AND userId == %@", eventId, participantId)
        
        do {
            let participants = try context.fetch(fetchRequest)
            
            if let participant = participants.first {
                context.delete(participant)
                try context.save()
                return true
            }
            
            return false
        } catch {
            print("Error removing participant: \(error)")
            return false
        }
    }
    
    // Update an event's capacity
    func updateEventCapacity(eventId: String, newCapacity: Int, context: NSManagedObjectContext) -> Bool {
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", eventId)
        
        do {
            let events = try context.fetch(fetchRequest)
            
            if let event = events.first {
                // Get current participant count
                let participantCount = getEventParticipants(eventId: eventId, context: context).count
                
                // Ensure new capacity is not less than current participant count
                if newCapacity < participantCount {
                    return false
                }
                
                event.capacity = Int32(newCapacity)
                event.spotsRemaining = Int32(newCapacity - participantCount)
                
                try context.save()
                return true
            }
            
            return false
        } catch {
            print("Error updating event capacity: \(error)")
            return false
        }
    }
}

// This extension defines a custom entity since EventInvite is not in the Core Data model yet
extension NSManagedObjectContext {
    func createEventInviteEntity() {
        let entity = NSEntityDescription()
        entity.name = "EventInvite"
        entity.managedObjectClassName = "EventInvite"
        
        // Define attributes
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .stringAttributeType
        idAttribute.isOptional = false
        
        let eventIdAttribute = NSAttributeDescription()
        eventIdAttribute.name = "eventId"
        eventIdAttribute.attributeType = .stringAttributeType
        eventIdAttribute.isOptional = false
        
        let inviteeIdAttribute = NSAttributeDescription()
        inviteeIdAttribute.name = "inviteeId"
        inviteeIdAttribute.attributeType = .stringAttributeType
        inviteeIdAttribute.isOptional = false
        
        let inviteDateAttribute = NSAttributeDescription()
        inviteDateAttribute.name = "inviteDate"
        inviteDateAttribute.attributeType = .dateAttributeType
        inviteDateAttribute.isOptional = true
        
        let statusAttribute = NSAttributeDescription()
        statusAttribute.name = "status"
        statusAttribute.attributeType = .stringAttributeType
        statusAttribute.isOptional = true
        
        // Add attributes to entity
        entity.properties = [idAttribute, eventIdAttribute, inviteeIdAttribute, inviteDateAttribute, statusAttribute]
        
        // Add entity to model
        if let model = self.persistentStoreCoordinator?.managedObjectModel {
            var entities = model.entities
            entities.append(entity)
            model.entities = entities
        }
    }
}

// Custom EventInvite class (since it's not in the Core Data model yet)
class EventInvite: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var eventId: String?
    @NSManaged var inviteeId: String?
    @NSManaged var inviteDate: Date?
    @NSManaged var status: String?
}

extension EventInvite {
    static func fetchRequest() -> NSFetchRequest<EventInvite> {
        return NSFetchRequest<EventInvite>(entityName: "EventInvite")
    }
}

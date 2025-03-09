import SwiftUI

// Card view for playdates in the grid
struct PlaydateCardView: View {
    let playdate: PlaydatePreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Playdate image with date overlay
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1.2, contentMode: .fit)
                    .overlay(
                        Text("🧩")
                            .font(.system(size: 40))
                    )
                
                // Date badge overlay
                HStack(spacing: 4) {
                    VStack(spacing: 0) {
                        Text(playdateFormatDay(playdate.date))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(playdateFormatDayNumber(playdate.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AppPrimaryColor"))
                    .cornerRadius(8)
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(playdate.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(playdateFormatTime(playdate.date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text(playdate.location)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Host name
                HStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color("AppPrimaryColor").opacity(0.7))
                    
                    Text("Host: \(playdate.hostName)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .foregroundColor(.primary) // Ensure text isn't blue when in a NavigationLink
    }
    
    private func formatDay(_ date: Date) -> String {
        return playdateFormatDay(date)
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        return playdateFormatDayNumber(date)
    }
    
    private func formatTime(_ date: Date) -> String {
        return playdateFormatTime(date)
    }
}

// Format helper functions - these might be shared with other views
func playdateFormatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

func playdateFormatDay(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE"
    return formatter.string(from: date)
}

func playdateFormatDayNumber(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter.string(from: date)
}

func playdateFormatMonth(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    return formatter.string(from: date)
}

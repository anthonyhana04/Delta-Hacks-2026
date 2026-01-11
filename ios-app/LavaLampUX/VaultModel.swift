import SwiftUI

enum VaultType: String, CaseIterable {
    case personal = "Personal"
    case work = "Work"
    case family = "Family"
    case social = "Social Media"
    
    var color: Color {
        switch self {
        case .personal: return Color(red: 0.6, green: 0.8, blue: 1.0) // Pastel Blue
        case .work: return Color(red: 1.0, green: 0.8, blue: 0.6) // Pastel Orange
        case .family: return Color(red: 0.7, green: 0.9, blue: 0.7) // Pastel Green
        case .social: return Color(red: 0.9, green: 0.7, blue: 0.9) // Pastel Purple
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .family: return "house.fill"
        case .social: return "message.fill"
        }
    }
}

struct VaultItem: Identifiable {
    let id = UUID()
    let type: VaultType
    let itemCount: Int
}

struct PasswordItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let username: String
    let password: String // New field
    let websiteUrl: String // New field
    let brandColor: Color
    let iconInitial: String
    
    static func == (lhs: PasswordItem, rhs: PasswordItem) -> Bool {
        return lhs.id == rhs.id && 
               lhs.name == rhs.name && 
               lhs.username == rhs.username &&
               lhs.password == rhs.password &&
               lhs.websiteUrl == rhs.websiteUrl &&
               lhs.iconInitial == rhs.iconInitial
    }
}

// Mock Data
extension PasswordItem {
    static func mockData(for type: VaultType) -> [PasswordItem] {
        switch type {
        case .social:
            return [
                PasswordItem(name: "Instagram", username: "user_insta", password: "instaPassword123", websiteUrl: "instagram.com", brandColor: .purple, iconInitial: "I"),
                PasswordItem(name: "Twitter", username: "@user_tweet", password: "tweetPass!@#", websiteUrl: "twitter.com", brandColor: .blue, iconInitial: "T"),
                PasswordItem(name: "Facebook", username: "fb.com/user", password: "fbSecureLogin", websiteUrl: "facebook.com", brandColor: .blue.opacity(0.8), iconInitial: "F")
            ]
        case .personal:
            return [
                PasswordItem(name: "Netflix", username: "chill@example.com", password: "watchingMovies!", websiteUrl: "netflix.com", brandColor: .red, iconInitial: "N"),
                PasswordItem(name: "Spotify", username: "music_lover", password: "musicIsLife456", websiteUrl: "spotify.com", brandColor: .green, iconInitial: "S"),
                PasswordItem(name: "Amazon", username: "prime_user", password: "primeDelivery789", websiteUrl: "amazon.com", brandColor: .orange, iconInitial: "A")
            ]
        case .work:
            return [
                PasswordItem(name: "Grammarly", username: "editor@work.com", password: "grammarPolice", websiteUrl: "grammarly.com", brandColor: .green, iconInitial: "G"),
                PasswordItem(name: "Slack", username: "dev_team", password: "slackChannelKey", websiteUrl: "slack.com", brandColor: .purple.opacity(0.8), iconInitial: "S"),
                PasswordItem(name: "Jira", username: "ticket_master", password: "jiraTicket#101", websiteUrl: "atlassian.com", brandColor: .blue, iconInitial: "J")
            ]
        case .family:
            return [
                PasswordItem(name: "Disney+", username: "kids_profile", password: "mickeyMouse1", websiteUrl: "disneyplus.com", brandColor: .blue, iconInitial: "D"),
                PasswordItem(name: "Hulu", username: "family_plan", password: "huluShows2024", websiteUrl: "hulu.com", brandColor: .green, iconInitial: "H")
            ]
        }
    }
}

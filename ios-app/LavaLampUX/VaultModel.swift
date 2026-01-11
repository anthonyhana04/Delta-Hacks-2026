import SwiftUI
import Combine

// 1. Vault Group Model
struct VaultGroup: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String 
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    init(id: UUID = UUID(), name: String, icon: String, color: Color) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = color.toHex() ?? "#0000FF"
    }
    
    // Default Groups helper
    static let allGroupsId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case colorHex = "color"
    }
}

// 2. Password Item Model
struct PasswordItem: Identifiable, Codable, Equatable {
    var id: UUID 
    var groupID: UUID? 
    
    var name: String
    var username: String
    var password: String
    var websiteUrl: String
    var brandColorHex: String
    var iconInitial: String
    
    // New fields for generated passwords
    var s3Key: String?
    var wallpaperS3Key: String?
    var wallpaperUrl: String? // Signed URL from backend
    
    var brandColor: Color {
        Color(hex: brandColorHex) ?? .gray
    }
    
    init(id: UUID = UUID(), groupID: UUID? = nil, name: String, username: String, password: String, websiteUrl: String, brandColor: Color, iconInitial: String, s3Key: String? = nil, wallpaperS3Key: String? = nil, wallpaperUrl: String? = nil) {
        self.id = id
        self.groupID = groupID
        self.name = name
        self.username = username
        self.password = password
        self.websiteUrl = websiteUrl
        self.brandColorHex = brandColor.toHex() ?? "#808080"
        self.iconInitial = iconInitial
        self.s3Key = s3Key
        self.wallpaperS3Key = wallpaperS3Key
        self.wallpaperUrl = wallpaperUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupID
        case name
        case username
        case password
        case websiteUrl = "website_url"
        case brandColorHex = "brand_color"
        case iconInitial = "icon_initial"
        case s3Key = "s3_key"
        case wallpaperS3Key = "wallpaper_s3_key"
        case wallpaperUrl = "wallpaper_url"
    }
}

// 3. Vault Group Manager (API Persistence)
class VaultGroupManager: ObservableObject {
    @Published var groups: [VaultGroup] = []
    
    // In a real app, use a configuration or env var
    private let baseURL = "\(APIConfig.baseURL)/api"
    
    init() {
        // We load groups on init or View can trigger it
        // fetchGroups()
    }
    
    func fetchGroups() {
        guard let url = URL(string: "\(baseURL)/groups") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching groups: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoded = try JSONDecoder().decode([VaultGroup].self, from: data)
                DispatchQueue.main.async {
                    self.groups = decoded
                }
            } catch {
                print("Error decoding groups: \(error)")
            }
        }.resume()
    }
    
    func addGroup(name: String, icon: String, color: Color) {
        guard let url = URL(string: "\(baseURL)/groups") else { return }
        
        // Optimistic UI update? Or wait for response? 
        // Let's optimistic -> revert on fail, or just wait. Waiting is safer for ID sync.
        
        let newGroupReq = VaultGroup(name: name, icon: icon, color: color)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(newGroupReq)
        } catch {
            print("Encoding error: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let createdGroup = try? JSONDecoder().decode(VaultGroup.self, from: data) {
                DispatchQueue.main.async {
                    self.groups.append(createdGroup)
                }
            }
        }.resume()
    }
    
    func deleteGroup(at offsets: IndexSet) {
        // Handle multiple deletions
        offsets.forEach { index in
            let group = groups[index]
            deleteGroupID(group.id)
        }
        
        // Optimistic local remove
        groups.remove(atOffsets: offsets)
    }
    
    // Explicit delete by object (used in context menu)
    func deleteGroup(_ group: VaultGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups.remove(at: index)
            deleteGroupID(group.id)
        }
    }
    
    private func deleteGroupID(_ id: UUID) {
        let urlString = "\(baseURL)/groups/\(id.uuidString.lowercased())"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error deleting group: \(error)")
            }
        }.resume()
    }
}

// Helper Extensions for Color Serialization
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String? {
        // Simple conversion for basic sRGB colors
        // Note: This matches standard SwiftUI Color behavior better in iOS 14+
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        // Handle varying component counts (grayscale vs rgba)
        let r, g, b: CGFloat
        
        if components.count >= 3 {
             r = components[0]
             g = components[1]
             b = components[2]
        } else {
            // Grayscale
            r = components[0]
            g = components[0]
            b = components[0]
        }

        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}


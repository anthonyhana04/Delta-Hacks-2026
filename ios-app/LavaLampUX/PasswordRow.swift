import SwiftUI

struct PasswordRow: View {
    let item: PasswordItem
    var onDelete: () -> Void
    
    @State private var isExpanded: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var showWallpaper: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row Content (Tap to Expand)
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(item.brandColor)
                                .frame(width: 44, height: 44)
                            
                            Text(item.iconInitial)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        // Wallpaper Indicator
                         if item.wallpaperUrl != nil && !item.wallpaperUrl!.isEmpty {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                                .padding(4)
                                .background(Color.black)
                                .clipShape(Circle())
                                .offset(x: 4, y: 4)
                        }
                    }
                    .shadow(color: item.brandColor.opacity(0.4), radius: 5, x: 0, y: 3)
                    
                    // Text Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(item.username)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Delete Button (Separate Action)
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red.opacity(0.8))
                            .font(.system(size: 16, weight: .medium))
                            .padding(8)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle()) // Make full row tappable
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(Color.white.opacity(0.2))
                    
                    // Website
                    DetailRow(icon: "link", label: "Website", value: item.websiteUrl)
                    
                    // Username
                    DetailRow(icon: "person.fill", label: "Username", value: item.username)
                    
                    // Password
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if isPasswordVisible {
                                Text(item.password)
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                            } else {
                                Text("••••••••••••")
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Wallpaper View Button
                    if let wpUrl = item.wallpaperUrl, !wpUrl.isEmpty {
                        Divider().background(Color.white.opacity(0.1))
                        
                        Button(action: { showWallpaper = true }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("View Entropy Source")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        // Wallpaper Viewer Sheet
        .sheet(isPresented: $showWallpaper) {
            ZStack {
                // Glassy Background
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    Text("Entropy Source")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                        
                    if let url = URL(string: item.wallpaperUrl ?? "") {
                        AsyncImage(url: url) { phase in
                             switch phase {
                             case .empty:
                                 ProgressView().tint(.white)
                             case .success(let image):
                                 image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .cornerRadius(16)
                                     .overlay(
                                         RoundedRectangle(cornerRadius: 16)
                                             .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                     )
                             case .failure:
                                 Image(systemName: "exclamationmark.triangle").foregroundColor(.red)
                             @unknown default:
                                 EmptyView()
                             }
                        }
                        .frame(maxHeight: 500)
                        
                        Text("This unique pattern was generated from chaotic lava lamp movements, providing true randomness for your key.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

struct PasswordRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PasswordRow(item: PasswordItem(name: "Netflix", username: "user@example.com", password: "password123", websiteUrl: "netflix.com", brandColor: .red, iconInitial: "N"), onDelete: {})
                .padding()
        }
    }
}

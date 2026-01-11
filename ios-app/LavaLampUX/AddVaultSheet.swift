import SwiftUI

struct AddVaultSheet: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (VaultGroup) -> Void
    
    @State private var vaultName: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: Color = Color(red: 0.6, green: 0.8, blue: 1.0)
    
    // Preset color palette
    let presetColors: [Color] = [
        Color(red: 0.6, green: 0.8, blue: 1.0),   // Pastel Blue
        Color(red: 1.0, green: 0.8, blue: 0.6),   // Pastel Orange
        Color(red: 0.7, green: 0.9, blue: 0.7),   // Pastel Green
        Color(red: 0.9, green: 0.7, blue: 0.9),   // Pastel Purple
        Color(red: 1.0, green: 0.7, blue: 0.8),   // Pastel Pink
        Color(red: 0.7, green: 0.9, blue: 0.9),   // Pastel Cyan
        Color(red: 1.0, green: 0.9, blue: 0.6),   // Pastel Yellow
        Color(red: 0.9, green: 0.8, blue: 0.7),   // Pastel Peach
        Color(red: 0.8, green: 0.7, blue: 1.0),   // Pastel Lavender
        Color(red: 0.7, green: 1.0, blue: 0.8),   // Pastel Mint
        Color(red: 1.0, green: 0.8, blue: 0.9),   // Pastel Rose
        Color(red: 0.8, green: 0.9, blue: 1.0)    // Pastel Sky
    ]
    
    // Available SF Symbols for vault icons
    let availableIcons = [
        "folder.fill", "star.fill", "heart.fill", "bookmark.fill",
        "flag.fill", "tag.fill", "paperplane.fill", "envelope.fill",
        "phone.fill", "video.fill", "camera.fill", "photo.fill",
        "cart.fill", "creditcard.fill", "gift.fill", "gamecontroller.fill"
    ]
    
    var body: some View {
        ZStack {
            // Background matching the main view
            Color(red: 0.05, green: 0.05, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("New Vault")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for symmetry
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Vault Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vault Name")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("Enter vault name", text: $vaultName)
                                .font(.system(size: 18, design: .rounded))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        // Icon Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Icon")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        Circle()
                                            .fill(selectedIcon == icon ? selectedColor.opacity(0.3) : Color(red: 0.1, green: 0.1, blue: 0.15))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: icon)
                                                    .foregroundColor(selectedIcon == icon ? selectedColor : .white.opacity(0.6))
                                                    .font(.system(size: 24))
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedIcon == icon ? selectedColor : Color.white.opacity(0.1), lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Color")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                                ForEach(Array(presetColors.enumerated()), id: \.offset) { index, color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 4 : 0)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .overlay(
                                                selectedColor == color ?
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 24))
                                                    .shadow(color: .black.opacity(0.3), radius: 2)
                                                : nil
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Create Button
                        Button(action: {
                            createVault()
                        }) {
                            Text("Create Group")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [selectedColor, selectedColor.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .disabled(vaultName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(vaultName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private func createVault() {
        let trimmedName = vaultName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        // Return new group via closure
        let newGroup = VaultGroup(
            name: trimmedName,
            icon: selectedIcon,
            color: selectedColor
        )
        
        onAdd(newGroup)
        dismiss()
    }
}


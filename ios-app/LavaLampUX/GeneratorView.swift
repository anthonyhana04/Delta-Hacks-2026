import SwiftUI

struct GeneratorView: View {
    @Environment(\.selectedTab) var selectedTab
    
    // Password Generation States
    @State private var password = ""
    @State private var isVisible = false
    @State private var length = 16.0
    @State private var isImageVisible = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Animated Lava Lamp
                LavaLampBackground()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Generator")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        VStack {
                            VStack(spacing: 24) {
                                // Password Display Card
                                VStack(spacing: 20) {
                                    Text("Lava Entropy Password")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                        .tracking(1)
                                    
                                    HStack {
                                        if isVisible {
                                            Text(password.isEmpty ? "••••••••••••••••" : password)
                                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                        } else {
                                            Text("••••••••••••••••")
                                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.3))
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: { isVisible.toggle() }) {
                                            Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 20))
                                        }
                                    }
                                    .padding(24)
                                    .background(Color.white.opacity(0.05))
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .padding(.top, 10)
                                
                                // Entropy Source Image Dropdown
                                VStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            isImageVisible.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "photo.fill")
                                                .foregroundColor(.purple)
                                            Text("View Entropy Source")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.white.opacity(0.5))
                                                .rotationEffect(.degrees(isImageVisible ? 180 : 0))
                                        }
                                        .padding(16)
                                        .background(Color.white.opacity(0.05))
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(16)
                                    }
                                    
                                    if isImageVisible {
                                        VStack {
                                            // Placeholder for the Lava Lamp Image
                                            Image("lava_lamp_entropy_source")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 400) // Increased height as requested
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                                .shadow(color: .black.opacity(0.3), radius: 10)
                                                .padding(.top, 12)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                        isImageVisible = false
                                                    }
                                                }
                                            
                                            Text("Entropy derived from physical fluid dynamics")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.4))
                                                .padding(.top, 8)
                                        }
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                    }
                                }
                                
                                // Settings Section
                                VStack(alignment: .leading, spacing: 20) {
                                    Text("Settings")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    // Length Slider
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Length")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                            Spacer()
                                            Text("\(Int(length))")
                                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Slider(value: $length, in: 8...32, step: 1)
                                            .tint(.blue)
                                            .onChange(of: length) { _ in
                                                generatePassword()
                                            }
                                    }
                                    .padding(20)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 120) // Extra space for Dock
                        }
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Dock
                VStack {
                    Spacer()
                    DockView(selectedTab: selectedTab)
                }
            }
            .toolbar(.hidden)
            .onAppear {
                if password.isEmpty { generatePassword() }
            }
        }
    }
    
    private func generatePassword() {
        let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        password = String((0..<Int(length)).map { _ in charset.randomElement()! })
    }
}


struct GeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        GeneratorView()
    }
}

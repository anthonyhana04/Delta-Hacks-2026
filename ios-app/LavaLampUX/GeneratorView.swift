import SwiftUI

struct GeneratorView: View {
    @Binding var selectedTab: TabItem

    // Password Generation States
    @State private var password = ""
    @State private var isVisible = false
    @State private var length = 16.0
    @State private var isImageVisible = false
    @State private var isGenerated = false
    @State private var s3Key: String?
    @State private var wallpaperS3Key: String?
    @State private var wallpaperURL: String?
    
    // Save Sheet State
    @State private var showSaveSheet = false
    @State private var saveName = ""
    @State private var saveUsername = ""
    @State private var saveUrl = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            // Background - Animated Lava Lamp
            LavaLampBackground()

            VStack(spacing: 0) {
                Spacer() // Push content to center
                
                // Main Content Card
                VStack(spacing: 32) {
                    
                    // 1. Password Display Area
                    VStack(spacing: 20) {
                        // Header Row with Controls
                        ZStack {
                            Text("GENERATED PASSWORD")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            if isGenerated {
                                HStack {
                                    // Copy Button (Top Left)
                                    Button(action: {
                                        UIPasteboard.general.string = password
                                    }) {
                                        Image(systemName: "doc.on.doc.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.system(size: 16))
                                            .padding(8)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    
                                    Spacer()
                                    
                                    // Eye Button (Top Right)
                                    Button(action: { isVisible.toggle() }) {
                                        Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.system(size: 16))
                                            .padding(8)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }
                        
                        ZStack {
                            if isGenerated {
                                if isVisible {
                                    Text(password)
                                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                } else {
                                    Text("••••••••••")
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            } else {
                                Text("Tap Generate")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // 2. Length Slider (Minimal)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Length")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(Int(length))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Slider(value: $length, in: 8...32, step: 1)
                            .tint(.white)
                    }
                    .padding(.horizontal, 10)
                    
                    // 3. Action Buttons
                    VStack(spacing: 24) {
                        Button(action: {
                            generatePassword()
                        }) {
                            Text(isGenerated ? "Regenerate" : "Generate Password")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        
                        if isGenerated {
                            HStack(spacing: 0) {
                                Button(action: {
                                    isImageVisible = true
                                }) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("View Entropy") 
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showSaveSheet = true
                                }) {
                                    Image(systemName: "square.and.arrow.down.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 24)
                                        .frame(height: 52)
                                        .background(Color.blue)
                                        .cornerRadius(30)
                                        .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 3)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer() // Balance visual center upwards a bit
            }
            .padding(.bottom, 80) // Space for Dock
 
            // Dock
        }
        .toolbar(.hidden)
        // Popup Sheet for Entropy Source
        .sheet(isPresented: $isImageVisible) {
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
                    
                    if let urlString = wallpaperURL, let url = URL(string: urlString) {
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
        // Save Sheet
        .sheet(isPresented: $showSaveSheet) {
            ZStack {
                // Glassy Background
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    Text("Save Password")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    
                    VStack(spacing: 20) {
                        CustomTextField(placeholder: "Website Name", text: $saveName)
                        CustomTextField(placeholder: "Website URL", text: $saveUrl)
                        CustomTextField(placeholder: "Username / Email", text: $saveUsername)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: { showSaveSheet = false }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                        }
                        
                        Button(action: savePassword) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save to Vault")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .disabled(saveName.isEmpty || saveUsername.isEmpty || isSaving)
                        .opacity(saveName.isEmpty || saveUsername.isEmpty || isSaving ? 0.5 : 1.0)
                    }
                    .padding(24)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // Response Model
    struct GenerationResponse: Codable {
        let password: String
        let image_url: String
        let wallpaper_url: String
        let entropy_bits: Int64
        let s3_key: String
        let wallpaper_s3_key: String
    }
    
    struct SaveRequest: Codable {
        let password: String
        let name: String
        let username: String
        let website_url: String
        let s3_key: String?
        let wallpaper_s3_key: String?
    }

    private func generatePassword() {
        guard let url = URL(string: "http://localhost:8080/api/generate-password") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Int] = ["length": Int(length)]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Generation Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    let result = try JSONDecoder().decode(GenerationResponse.self, from: data)
                    
                    self.password = result.password
                    self.wallpaperURL = result.wallpaper_url
                    self.s3Key = result.s3_key
                    self.wallpaperS3Key = result.wallpaper_s3_key
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.isGenerated = true
                        self.isVisible = false 
                    }
                } catch {
                    print("Decoding Error: \(error)")
                }
            }
        }.resume()
    }
    
    private func savePassword() {
        guard let url = URL(string: "http://localhost:8080/api/passwords") else { return }
        
        isSaving = true
        
        let reqBody = SaveRequest(
            password: password,
            name: saveName,
            username: saveUsername,
            website_url: saveUrl,
            s3_key: s3Key,
            wallpaper_s3_key: wallpaperS3Key
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(reqBody)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                isSaving = false
                if error == nil {
                    showSaveSheet = false
                    // Reset form
                    saveName = ""
                    saveUsername = ""
                    saveUrl = ""
                    
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }.resume()
    }
}

struct GeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        GeneratorView(selectedTab: .constant(.generator))
    }
}

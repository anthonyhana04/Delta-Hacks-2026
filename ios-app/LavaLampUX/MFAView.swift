import Combine
import CryptoKit
import SwiftUI
import UIKit

struct MFAItem: Identifiable {
    let id = UUID()
    let issuer: String
    let accountName: String
    let color: Color
    // currentCode is now computed dynamically
}

struct MFAResponse: Codable {
    let seed: String
    let valid_until: String
}

struct MFAView: View {
    @Binding var selectedTab: TabItem

    // Sheet State
    @State private var showAddSheet = false
    @State private var searchText = ""

    // Global Timer State
    @State private var timeRemaining: Double = 60.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // 2FA Logic State
    @State private var currentBaseSeed: String = ""
    @State private var nextBaseSeed: String? = nil
    @State private var isFetching = false

    // Mock Data - Only 2 initially
    @State private var mfaItems: [MFAItem] = [
        MFAItem(
            issuer: "Google", accountName: "anthonyhana04@gmail.com", color: .blue),
        MFAItem(
            issuer: "Discord", accountName: "spiderboy#1234", color: .indigo
        ),
    ]

    // Filtered Items for Search
    var filteredItems: [MFAItem] {
        if searchText.isEmpty {
            return mfaItems
        } else {
            return mfaItems.filter {
                $0.issuer.localizedCaseInsensitiveContains(searchText)
                    || $0.accountName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            // Background - Animated Lava Lamp
            LavaLampBackground()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 16) {
                    Text("Authenticator")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Add Button
                    Button(action: {
                        showAddSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    // Small Global Timer in Top Right
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)

                        Circle()
                            .trim(from: 0, to: timeRemaining / 60.0)
                            .stroke(
                                timeRemaining < 10 ? Color.red : Color.blue,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: timeRemaining)

                        Text("\(Int(ceil(timeRemaining)))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search accounts...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(.blue)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Scrollable List of Codes
                ScrollView {
                    VStack(spacing: 16) {
                        // Real Items (Filtered)
                        ForEach(filteredItems) { item in
                            let code = deriveCode(item: item)
                            Button(action: {
                                // Copy to Clipboard (removing spaces)
                                let codeToCopy = code.replacingOccurrences(
                                    of: " ", with: "")
                                UIPasteboard.general.string = codeToCopy

                                // Haptic Feedback
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }) {
                                MFACard(item: item, code: code, timeRemaining: timeRemaining)
                            }
                            .buttonStyle(FadeButtonStyle())
                        }

                        // Blank Placeholders to fill screen (min 6 total items visualized)
                        // If filtered results are less than 6, fill the rest with empty cards
                        if filteredItems.count < 6 {
                            ForEach(0..<(6 - filteredItems.count), id: \.self) { index in
                                EmptyMFACard(index: index)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)  // Spacing for Dock
                }
            }

            // Dock
        }
        .sheet(isPresented: $showAddSheet) {
            AddMFASheet(mfaItems: $mfaItems)
        }
        .toolbar(.hidden)
        .onAppear {
            fetchNextSeed()  // Initial fetch
        }
        .onReceive(timer) { _ in
            // Persistent Timer Logic: Sync with System Clock
            let now = Date()
            let second = Calendar.current.component(.second, from: now)
            // Optionally include nanoseconds for smoother animation if desired,
            // but integer seconds + linear animation is usually fine.
            // For smoother arc:
            let nanosecond = Calendar.current.component(.nanosecond, from: now)
            let accurateTime = Double(second) + Double(nanosecond) / 1_000_000_000.0

            withAnimation(.linear(duration: 0.1)) {
                timeRemaining = 60.0 - accurateTime
            }

            // Pre-fetch at 20s remaining (i.e., at 40s mark of the minute)
            if timeRemaining <= 20.0 && timeRemaining > 19.5 && nextBaseSeed == nil && !isFetching {
                print("Fetching next seed...")
                fetchNextSeed()
            }

            // At the turn of the minute (approx 0s remaining), switch seeds
            if timeRemaining < 0.2 {
                if let next = nextBaseSeed {
                    withAnimation {
                        currentBaseSeed = next
                    }
                    nextBaseSeed = nil
                    print("Updated to new seed: \(currentBaseSeed)")
                } else {
                    // Fallback: Try fetching again immediately if we missed it
                    if !isFetching {
                        print("No next seed ready, fetching now...")
                        fetchNextSeed(isImmediate: true)
                    }
                }
            }
        }
    }

    private func fetchNextSeed(isImmediate: Bool = false) {
        guard !isFetching else { return }
        isFetching = true

        guard let url = URL(string: "http://localhost:8080/api/mfa/generate") else {
            isFetching = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                self.isFetching = false
                if let error = error {
                    print("MFA Fetch Error: \(error.localizedDescription)")
                    return
                }

                if let data = data,
                    let response = try? JSONDecoder().decode(MFAResponse.self, from: data)
                {
                    if self.currentBaseSeed.isEmpty || isImmediate {
                        self.currentBaseSeed = response.seed
                    } else {
                        self.nextBaseSeed = response.seed
                    }
                }
            }
        }.resume()
    }

    private func deriveCode(item: MFAItem) -> String {
        if currentBaseSeed.isEmpty { return "Generating..." }

        let input = currentBaseSeed + item.issuer + item.accountName
        guard let inputData = input.data(using: .utf8) else { return "000 000" }

        let hashed = SHA256.hash(data: inputData)
        // Use first 4 bytes to get an integer
        let hashData = Data(hashed)
        let value = hashData.withUnsafeBytes { $0.load(as: UInt32.self) }

        // Ensure positive
        let code = Int(value) % 1_000_000
        let absCode = abs(code)

        let str = String(format: "%06d", absCode)
        return "\(str.prefix(3)) \(str.suffix(3))"
    }
}

struct MFACard: View {
    let item: MFAItem
    let code: String
    let timeRemaining: Double

    var body: some View {
        HStack {
            // Icon / Color Strip
            RoundedRectangle(cornerRadius: 4)
                .fill(item.color)
                .frame(width: 6)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.issuer)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(item.accountName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, 8)

            Spacer()

            // The Code
            Text(code)
                .font(
                    .system(
                        size: code == "Generating..." ? 18 : 28, weight: .bold, design: .monospaced)
                )
                .foregroundColor(timeRemaining < 10 ? .red : .white)
                .contentTransition(.numericText())
                .animation(.default, value: code)
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct EmptyMFACard: View {
    let index: Int

    var fadeOpacity: Double {
        // Start at 0.4 (more visible) and decrease by 0.08 for each index
        // Floor at 0.05
        return max(0.4 - (Double(index) * 0.08), 0.05)
    }

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05 * fadeOpacity * 2.5))  // Adjust baseline
                .frame(width: 6)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05 * fadeOpacity * 2.5))
                    .frame(width: 100, height: 18)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05 * fadeOpacity * 2.5))
                    .frame(width: 150, height: 14)
            }
            .padding(.leading, 8)

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05 * fadeOpacity * 2.5))
                .frame(width: 120, height: 28)
        }
        .padding(16)
        .background(Color.white.opacity(0.02 * fadeOpacity * 4.0))  // Make background slightly more visible
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05 * fadeOpacity * 2.5), lineWidth: 1)
        )
    }
}

struct AddMFASheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var mfaItems: [MFAItem]

    @State private var issuer: String = ""
    @State private var accountName: String = ""
    @State private var selectedColor: Color = .blue

    let colors: [Color] = [.blue, .purple, .orange, .red, .green, .pink, .gray, .yellow]

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 24) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 6)
                    .padding(.top, 10)

                Text("Add Authenticator")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    MFATextField(placeholder: "Service (e.g. Google)", text: $issuer)
                    MFATextField(placeholder: "Account (e.g. user@email.com)", text: $accountName)
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    Text("Label Color")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(.leading)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white,
                                                lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(
                                        color: color.opacity(0.5),
                                        radius: selectedColor == color ? 5 : 0
                                    )
                                    .onTapGesture {
                                        withAnimation {
                                            selectedColor = color
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()

                Button(action: addAccount) {
                    Text("Add Account")
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [selectedColor.opacity(0.8), selectedColor],
                                startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(issuer.isEmpty || accountName.isEmpty)
                .opacity(issuer.isEmpty || accountName.isEmpty ? 0.5 : 1)
            }
            .padding(.bottom, 20)
        }
    }

    private func addAccount() {
        let newItem = MFAItem(
            issuer: issuer,
            accountName: accountName,
            color: selectedColor
        )
        withAnimation {
            mfaItems.append(newItem)
        }
        dismiss()
    }
}

// Local helper to avoid dependency issues
struct MFATextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 16)
            }
            TextField("", text: $text)
                .foregroundColor(.white)
                .padding(16)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct MFAView_Previews: PreviewProvider {
    static var previews: some View {
        MFAView(selectedTab: .constant(.mfa))
    }
}

struct FadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.4 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: TabItem
    @EnvironmentObject var authManager: AuthManager

    // Settings States
    @State private var useBiometrics = false
    @State private var notificationsEnabled = false
    @State private var isPremium = true

    var body: some View {
        ZStack {
            // Background - Animated Lava Lamp
            LavaLampBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 10)

                ScrollView {
                    VStack {
                        VStack(spacing: 24) {

                            // 1. Account
                            SettingsSection(title: "Account") {
                                SettingsRow(
                                    icon: "person.crop.circle.fill", color: .blue,
                                    title: "Sign in Method", subtitle: "Google")
                            }

                            // 2. Security & Privacy
                            SettingsSection(title: "Security & Privacy") {
                                ToggleRow(
                                    icon: "faceid", color: .green, title: "Biometric Unlock",
                                    isOn: $useBiometrics)
                            }

                            // 3. App Preferences
                            SettingsSection(title: "App Preferences") {
                                ToggleRow(
                                    icon: "bell.fill", color: .red, title: "Notifications",
                                    isOn: $notificationsEnabled)
                            }

                            // 4. Support & About
                            SettingsSection(title: "Support & About") {
                                SettingsRow(
                                    icon: "questionmark.circle.fill", color: .gray,
                                    title: "Help Center", subtitle: "FAQs & Tutorials")
                                SettingsRow(
                                    icon: "envelope.fill", color: .cyan, title: "Contact Support",
                                    subtitle: "Get in touch")
                            }

                            // 5. Log Out
                            SettingsSection(title: "Log Out") {
                                Button(action: {
                                    // Log out action
                                    authManager.signOut()
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                        Text("Log Out")
                                            .foregroundColor(.red)
                                            .font(.system(size: 16, weight: .medium))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }

                            // Version (Minimal, outside bubble)
                            Text("Version 0.9.0 (Build 2026)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.top, 20)

                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        .padding(.bottom, 150)  // More space for Dock and bottom safe area
                    }
                    .frame(maxWidth: 600)
                    .frame(maxWidth: .infinity)
                }
            }

            // Dock
        }
        .toolbar(.hidden)
    }
}

// MARK: - Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Updated Header: More stylized, tracking for a modern feel
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.leading, 12)

            VStack(spacing: -1) {  // Pull rows closer for a tighter look
                content
            }
            .background(Color.white.opacity(0.04))
            .background(.ultraThinMaterial)
            .cornerRadius(24)  // Rounder corners
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 16) {
            // Updated Icon Style: Glowing Circle instead of solid square
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                Circle()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 36, height: 36)
            .shadow(color: color.opacity(0.2), radius: 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Updated Icon Style: Glowing Circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                Circle()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 36, height: 36)
            .shadow(color: color.opacity(0.2), radius: 5)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(selectedTab: .constant(.settings))
            .environmentObject(AuthManager())
    }
}

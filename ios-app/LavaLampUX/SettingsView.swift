import SwiftUI

struct SettingsView: View {
    @Binding var selectedTab: TabItem

    // Settings States
    @State private var useBiometrics = true
    @State private var notificationsEnabled = true
    @State private var analyticsEnabled = false
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

                            // 1. Account & Membership
                            SettingsSection(title: "Account & Membership") {
                                SettingsRow(
                                    icon: "person.crop.circle.fill", color: .blue,
                                    title: "Apple ID & Google", subtitle: "anthonyhana04@apple.com")
                                SettingsRow(
                                    icon: "person.2.fill", color: .purple, title: "Shared Accounts",
                                    subtitle: "3 People Sharing")

                                Divider().background(Color.white.opacity(0.1)).padding(
                                    .horizontal, 16)

                                HStack {
                                    SettingsRow(
                                        icon: "star.fill", color: .orange, title: "Membership",
                                        subtitle: isPremium ? "Premium Active" : "Free Plan")
                                    Spacer()
                                    if !isPremium {
                                        Text("UPGRADE")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.orange)
                                            .cornerRadius(8)
                                    }
                                }
                            }

                            // 2. Security & Privacy
                            SettingsSection(title: "Security & Privacy") {
                                ToggleRow(
                                    icon: "faceid", color: .green, title: "Biometric Unlock",
                                    isOn: $useBiometrics)
                                SettingsRow(
                                    icon: "key.fill", color: .yellow, title: "Password Management",
                                    subtitle: "Update Master Key")

                                Divider().background(Color.white.opacity(0.1)).padding(
                                    .horizontal, 16)

                                Button(action: {
                                    // Action for emergency lock
                                }) {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(.red)
                                            .frame(width: 30)
                                        Text("Emergency Vault Lock")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }

                            // 3. App Preferences
                            SettingsSection(title: "App Preferences") {
                                ToggleRow(
                                    icon: "bell.fill", color: .red, title: "Notifications",
                                    isOn: $notificationsEnabled)
                                ToggleRow(
                                    icon: "chart.bar.fill", color: .blue, title: "Usage Analytics",
                                    isOn: $analyticsEnabled)
                            }

                            // 4. Support & About
                            SettingsSection(title: "Support & About") {
                                SettingsRow(
                                    icon: "questionmark.circle.fill", color: .gray,
                                    title: "Help Center", subtitle: "FAQs & Tutorials")
                                SettingsRow(
                                    icon: "envelope.fill", color: .cyan, title: "Contact Support",
                                    subtitle: "Get in touch")

                                Divider().background(Color.white.opacity(0.1)).padding(
                                    .horizontal, 16)

                                HStack {
                                    Text("Version")
                                        .foregroundColor(.white.opacity(0.5))
                                    Spacer()
                                    Text("2.4.0 (Build 2026)")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }

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
            VStack {
                Spacer()
                DockView(selectedTab: $selectedTab)
            }
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
    }
}

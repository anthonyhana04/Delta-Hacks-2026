import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .vaults
    
    var body: some View {
        ZStack {
            // Background - Animated Lava Lamp
            LavaLampBackground()
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .vaults:
                    VaultView()
                case .mfa:
                    MFAView()
                case .generator:
                    GeneratorView()
                case .settings:
                    SettingsView()
                }
            }
            .transition(.opacity)
        }
        .environment(\.selectedTab, $selectedTab)
    }
}

// Environment key for sharing selectedTab across views
private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<TabItem> = .constant(.vaults)
}

extension EnvironmentValues {
    var selectedTab: Binding<TabItem> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

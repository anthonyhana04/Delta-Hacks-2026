import SwiftUI

enum TabItem: String, CaseIterable {
    case vaults = "Vaults"
    case mfa = "MFA"
    case generator = "Generator"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .vaults: return "lock.fill"
        case .mfa: return "shield.fill"
        case .generator: return "key.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct DockView: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                DockButton(tab: tab, selectedTab: $selectedTab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.8))
        .cornerRadius(35)
        .overlay(
            RoundedRectangle(cornerRadius: 35)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct DockButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    
    var isSelected: Bool {
        selectedTab == tab
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 70, height: 70) // Slightly increased size to fit text comfortable
            .background(Color(red: 0.05, green: 0.05, blue: 0.1))
            .cornerRadius(20) // Adjusted radius for new size
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 4)
        }
    }
}

struct DockView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            VStack {
                Spacer()
                DockView(selectedTab: .constant(.vaults))
            }
        }
    }
}

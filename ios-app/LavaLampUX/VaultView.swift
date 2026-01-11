import SwiftUI

struct VaultView: View {
    @State private var selectedTab: TabItem = .vaults
    @State private var expandedVaultType: VaultType? = nil
    
    // Master Source of Truth
    // Initializes with the mock data we defined in VaultModel
    @State private var vaultData: [VaultType: [PasswordItem]] = Dictionary(uniqueKeysWithValues: 
        VaultType.allCases.map { type in (type, PasswordItem.mockData(for: type)) }
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Animated Lava Lamp
                LavaLampBackground()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("My Vaults")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 20) { // Vertical Stack for Accordion
                            // We iterate over the keys (types) in a stable order
                            ForEach(VaultType.allCases, id: \.self) { type in
                                let count = vaultData[type]?.count ?? 0
                                let item = VaultItem(type: type, itemCount: count)
                                
                                VStack(spacing: 0) {
                                    // The Card (Clickable)
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            if expandedVaultType == type {
                                                expandedVaultType = nil // Collapse
                                            } else {
                                                expandedVaultType = type // Expand
                                            }
                                        }
                                    }) {
                                        VaultCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // The Dropdown Content
                                    if expandedVaultType == type {
                                        // Pass a binding to the specific array in the dictionary
                                        PasswordListView(vaultType: type, items: Binding(
                                            get: { vaultData[type] ?? [] },
                                            set: { vaultData[type] = $0 }
                                        ))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                        .zIndex(-1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120) // Extra space for Dock
                    }
                }
                
                // Dock
                VStack {
                    Spacer()
                    DockView(selectedTab: $selectedTab)
                }
            }
            .toolbar(.hidden) // Hide default nav bar
        }
    }
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}

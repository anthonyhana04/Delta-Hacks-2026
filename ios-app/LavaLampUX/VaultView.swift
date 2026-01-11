import SwiftUI

struct VaultView: View {
    @State private var selectedTab: TabItem = .vaults
    @State private var expandedVaultType: VaultType? = nil
    @State private var expandedCustomVaultId: UUID? = nil  // Track custom vault expansion
    @State private var showAddVaultSheet = false
    @State private var customVaults: [CustomVaultCategory] = []

    // Store items for custom vaults
    @State private var customVaultItems: [UUID: [PasswordItem]] = [:]

    // Master Source of Truth
    // Initializes with the mock data we defined in VaultModel
    @State private var vaultData: [VaultType: [PasswordItem]] = Dictionary(
        uniqueKeysWithValues:
            VaultType.allCases.map { type in (type, PasswordItem.mockData(for: type)) }
    )

    @State private var transitionEdge: Edge = .trailing

    var body: some View {
        let tabSelectionBinding = Binding<TabItem>(
            get: { selectedTab },
            set: { newValue in
                if newValue.index > selectedTab.index {
                    transitionEdge = .trailing
                } else {
                    transitionEdge = .leading
                }
                withAnimation {
                    selectedTab = newValue
                }
            }
        )

        ZStack {
            // Content Layer with Transitions
            Group {
                switch selectedTab {
                case .generator:
                    GeneratorView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)
                            ))
                case .vaults:
                    NavigationView {
                        ZStack {
                            // Background
                            LavaLampBackground()
                            VStack(spacing: 0) {
                                // Header
                                HStack {
                                    Text("My Vaults")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()

                                    Button(action: {
                                        showAddVaultSheet = true
                                    }) {
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
                                    VStack {
                                        LazyVStack(spacing: 20) {
                                            ForEach(VaultType.allCases, id: \.self) { type in
                                                let count = vaultData[type]?.count ?? 0
                                                let item = VaultItem(type: type, itemCount: count)

                                                VStack(spacing: 0) {
                                                    Button(action: {
                                                        withAnimation(
                                                            .spring(
                                                                response: 0.4, dampingFraction: 0.7)
                                                        ) {
                                                            if expandedVaultType == type {
                                                                expandedVaultType = nil
                                                            } else {
                                                                expandedVaultType = type
                                                            }
                                                        }
                                                    }) {
                                                        VaultCard(item: item)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())

                                                    if expandedVaultType == type {
                                                        PasswordListView(
                                                            themeColor: type.color,
                                                            items: Binding(
                                                                get: { vaultData[type] ?? [] },
                                                                set: { vaultData[type] = $0 }
                                                            )
                                                        )
                                                        .transition(
                                                            .opacity.combined(
                                                                with: .move(edge: .top))
                                                        )
                                                        .zIndex(-1)
                                                    }
                                                }
                                            }

                                            ForEach(customVaults) { vault in
                                                VStack(spacing: 0) {
                                                    Button(action: {
                                                        withAnimation(
                                                            .spring(
                                                                response: 0.4, dampingFraction: 0.7)
                                                        ) {
                                                            if expandedCustomVaultId == vault.id {
                                                                expandedCustomVaultId = nil
                                                            } else {
                                                                expandedCustomVaultId = vault.id
                                                            }
                                                        }
                                                    }) {
                                                        CustomVaultCard(vault: vault)
                                                    }
                                                    .buttonStyle(PlainButtonStyle())

                                                    if expandedCustomVaultId == vault.id {
                                                        PasswordListView(
                                                            themeColor: vault.color,
                                                            items: Binding(
                                                                get: {
                                                                    customVaultItems[vault.id] ?? []
                                                                },
                                                                set: {
                                                                    customVaultItems[vault.id] = $0
                                                                }
                                                            )
                                                        )
                                                        .transition(
                                                            .opacity.combined(
                                                                with: .move(edge: .top))
                                                        )
                                                        .zIndex(-1)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.bottom, 120)
                                    }
                                    .frame(maxWidth: 600)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .background(Color.clear)
                        .toolbar(.hidden)
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: transitionEdge),
                            removal: .move(edge: transitionEdge == .trailing ? .leading : .trailing)
                        ))
                case .mfa:
                    MFAView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)
                            ))
                case .settings:
                    SettingsView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)
                            ))
                }
            }

            // Static Dock Layer (Outside Transitions)
            VStack {
                Spacer()
                DockView(selectedTab: tabSelectionBinding)
            }
        }
        .sheet(isPresented: $showAddVaultSheet) {
            AddVaultSheet(customVaults: $customVaults)
        }
        .onChange(of: customVaults) { newValue in
            if let newest = newValue.last, newValue.count > customVaults.count {
                // A new vault was added, expand it automatically
                withAnimation {
                    expandedCustomVaultId = newest.id
                    // Also ensure we initialize the storage (though default get/set handles it, explicit init is clean)
                    if customVaultItems[newest.id] == nil {
                        customVaultItems[newest.id] = []
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: selectedTab)  // Smooth transition for tab changes
    }
}

struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        VaultView()
    }
}

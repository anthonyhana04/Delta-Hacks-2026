import SwiftUI

struct VaultView: View {
    // Tab State
    @State private var selectedTab: TabItem = .vaults
    @State private var transitionEdge: Edge = .trailing

    // Data State
    @StateObject private var groupManager = VaultGroupManager()
    @State private var allPasswords: [PasswordItem] = []

    // UI State
    @State private var showAddVaultSheet = false

    // Grid Configuration
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        let tabSelectionBinding = Binding<TabItem>(
            get: { selectedTab },
            set: { newValue in
                if newValue.index > selectedTab.index {
                    transitionEdge = .trailing
                } else {
                    transitionEdge = .leading
                }
                withAnimation(.easeInOut(duration: 0.35)) {
                    selectedTab = newValue
                }
            }
        )

        ZStack {
            // Main Content Layer
            Group {
                switch selectedTab {
                case .generator:
                    GeneratorView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)))

                case .vaults:
                    NavigationView {
                        ZStack {
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

                                // Groups Grid
                                ScrollView {
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        // 1. "All Passwords" Group (Special Case)
                                        NavigationLink(
                                            destination: PasswordListView(
                                                groupID: nil,
                                                groupName: "All Passwords",
                                                themeColor: .blue,
                                                allItems: $allPasswords
                                            )
                                        ) {
                                            VaultGroupCard(
                                                name: "All Passwords",
                                                icon: "rectangle.stack.fill",
                                                color: .blue,
                                                count: allPasswords.count
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        // 2. Custom Groups
                                        ForEach(groupManager.groups) { group in
                                            NavigationLink(
                                                destination: PasswordListView(
                                                    groupID: group.id,
                                                    groupName: group.name,
                                                    themeColor: group.color,
                                                    allItems: $allPasswords,
                                                    onDeleteGroup: {
                                                        deleteGroup(group)
                                                    }
                                                )
                                            ) {
                                                VaultGroupCard(
                                                    name: group.name,
                                                    icon: group.icon,
                                                    color: group.color,
                                                    count: allPasswords.filter {
                                                        $0.groupID == group.id
                                                    }.count
                                                )
                                            }

                                            .buttonStyle(PlainButtonStyle())
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    deleteGroup(group)
                                                } label: {
                                                    Label("Delete Group", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 120)  // Space for dock
                                }
                            }
                        }
                        .navigationBarHidden(true)
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: transitionEdge),
                            removal: .move(edge: transitionEdge == .trailing ? .leading : .trailing)
                        )
                    )
                    .onAppear {
                        fetchPasswords()
                    }

                case .mfa:
                    MFAView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)))

                case .settings:
                    SettingsView(selectedTab: tabSelectionBinding)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: transitionEdge),
                                removal: .move(
                                    edge: transitionEdge == .trailing ? .leading : .trailing)))
                }
            }

            // Static Dock Layer
            VStack {
                Spacer()
                DockView(selectedTab: tabSelectionBinding)
            }
        }
        .sheet(isPresented: $showAddVaultSheet) {
            AddVaultSheet { newGroup in
                groupManager.addGroup(
                    name: newGroup.name, icon: newGroup.icon, color: newGroup.color)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: selectedTab)
    }

    private func deleteGroup(_ group: VaultGroup) {
        withAnimation {
            // 1. Update local passwords to remove group association
            for i in allPasswords.indices {
                if allPasswords[i].groupID == group.id {
                    allPasswords[i].groupID = nil
                }
            }

            // 2. Call Manager to handle API and list removal
            groupManager.deleteGroup(group)
        }
    }

    // MARK: - API Fetching
    // MARK: - API Fetching
    struct PasswordResponseEntry: Codable {
        let id: UUID
        let password: String
        let entropy_bits: Int64
        let wallpaper_url: String
        let created_at: String
        let group_id: UUID?
        // New Metadata
        let name: String?
        let username: String?
        let website_url: String?
    }

    private func fetchPasswords() {
        groupManager.fetchGroups()  // Also fetch groups!

        guard let url = URL(string: "http://localhost:8080/api/my-passwords") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Fetch Error: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let entries = try decoder.decode([PasswordResponseEntry].self, from: data)

                DispatchQueue.main.async {
                    self.allPasswords = entries.map { entry in
                        PasswordItem(
                            id: entry.id,
                            groupID: entry.group_id,
                            name: entry.name ?? "Generated Password",
                            username: entry.username ?? "User",
                            password: entry.password,
                            websiteUrl: entry.website_url ?? "",
                            brandColor: .purple,
                            iconInitial: String((entry.name ?? "P").prefix(1)),
                            wallpaperUrl: entry.wallpaper_url  // Map the signed URL
                        )
                    }
                }
            } catch {
                print("Decoding Error: \(error)")
            }
        }.resume()
    }
}

// MARK: - Helper Views

struct VaultGroupCard: View {
    let name: String
    let icon: String
    let color: Color
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(color)
                            .font(.system(size: 18, weight: .semibold))
                    )

                Spacer()

                Text("\(count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()

            Text(name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(16)
        .frame(height: 110)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

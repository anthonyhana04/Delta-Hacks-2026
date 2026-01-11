import SwiftUI

struct PasswordListView: View {
    let groupID: UUID?
    let groupName: String
    let themeColor: Color
    @Binding var allItems: [PasswordItem]
    var onDeleteGroup: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""

    // ... (Inline Add Form State remains matching original) ...
    @State private var isAdding = false
    @State private var newName = ""
    @State private var newUrl = ""
    @State private var newUsername = ""
    @State private var newPassword = ""

    // Filtered items based on Group AND Search
    var filteredItems: [PasswordItem] {
        let groupItems = allItems.filter { item in
            if let groupID = groupID {
                return item.groupID == groupID
            } else {
                return true  // "All" group shows everything
            }
        }

        if searchText.isEmpty {
            return groupItems
        } else {
            return groupItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        // ... (Body content mostly same, assuming generic views) ...
        // Re-declaring body to ensure context is safe
        ZStack {
            LavaLampBackground()

            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search \(groupName)...", text: $searchText)
                        .foregroundColor(.white)
                        .accentColor(themeColor)

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
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // List Content
                ScrollView {
                    VStack(spacing: 8) {
                        // Inline Add Form (At Top)
                        if isAdding {
                            VStack(spacing: 12) {
                                Text("New Password in \(groupName)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                CustomTextField(placeholder: "Website Name", text: $newName)
                                CustomTextField(placeholder: "Website URL", text: $newUrl)
                                CustomTextField(placeholder: "Username / Email", text: $newUsername)
                                CustomTextField(
                                    placeholder: "Password", text: $newPassword, isSecure: true)

                                HStack(spacing: 12) {
                                    Button(action: cancelAdd) {
                                        Text("Cancel")
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }

                                    Button(action: saveNewItem) {
                                        Text("Save")
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(themeColor)
                                            .cornerRadius(8)
                                    }
                                    .disabled(
                                        newName.isEmpty || newUsername.isEmpty
                                            || newPassword.isEmpty
                                    )
                                    .opacity(
                                        newName.isEmpty || newUsername.isEmpty
                                            || newPassword.isEmpty
                                            ? 0.5 : 1.0)
                                }
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                            .cornerRadius(16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        } else {
                            // Expand Button
                            Button(action: {
                                withAnimation(.spring()) {
                                    isAdding = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                    Text("Add Password")
                                        .font(
                                            .system(size: 16, weight: .semibold, design: .rounded)
                                        )
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(themeColor.opacity(0.2))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(themeColor.opacity(0.5), lineWidth: 1)
                                )
                            }
                            .transition(.opacity)
                        }

                        // Items
                        ForEach(filteredItems) { item in
                            PasswordRow(
                                item: item,
                                onDelete: {
                                    deleteItem(item)
                                }
                            )
                            .transition(.opacity.combined(with: .scale))
                        }

                        // Empty State
                        if filteredItems.isEmpty && !isAdding {
                            VStack(spacing: 16) {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("No passwords in this group yet")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(groupName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if onDeleteGroup != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            onDeleteGroup?()
                            dismiss()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .animation(.spring(), value: allItems)
    }

    private func deleteItem(_ item: PasswordItem) {
        // Call API
        guard
            let url = URL(
                string: "\(APIConfig.baseURL)/api/passwords/\(item.id.uuidString.lowercased())")
        else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()

        if let index = allItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation {
                allItems.remove(at: index)
            }
        }
    }

    struct CreatePasswordRequest: Codable {
        let password: String
        let group_id: UUID?
        let name: String
        let username: String
        let website_url: String
    }

    struct CreatePasswordResponse: Codable {
        let id: UUID
        let password: String
        let group_id: UUID?
    }

    private func saveNewItem() {
        let requestBody = CreatePasswordRequest(
            password: newPassword,
            group_id: groupID,
            name: newName,
            username: newUsername,
            website_url: newUrl
        )

        guard let url = URL(string: "\(APIConfig.baseURL)/api/passwords") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }

            if let response = try? JSONDecoder().decode(CreatePasswordResponse.self, from: data) {
                DispatchQueue.main.async {
                    let initial = self.newName.first.map { String($0).uppercased() } ?? "?"

                    let newItem = PasswordItem(
                        id: response.id,
                        groupID: response.group_id,
                        name: self.newName,  // These are local fields not in API response yet, but consistent
                        username: self.newUsername,
                        password: response.password,
                        websiteUrl: self.newUrl,
                        brandColor: themeColor,
                        iconInitial: initial
                    )

                    withAnimation {
                        allItems.append(newItem)
                        isAdding = false
                        cleanupForm()
                    }
                }
            }
        }.resume()
    }

    private func cancelAdd() {
        withAnimation {
            isAdding = false
            cleanupForm()
        }
    }

    private func cleanupForm() {
        newName = ""
        newUrl = ""
        newUsername = ""
        newPassword = ""
    }
}

// Helper for inputs (Re-declared here for completeness inside this file scope if needed, or verified exists)
// Note: If CustomTextField is reused elsewhere, moving it to a shared file is better, but since it was here, I will check if I need to keep it.
// It seems CustomTextField was here. I'll include it.
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }

            if isSecure {
                SecureField("", text: $text)
                    .padding(12)
                    .foregroundColor(.white)
            } else {
                TextField("", text: $text)
                    .padding(12)
                    .foregroundColor(.white)
            }
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

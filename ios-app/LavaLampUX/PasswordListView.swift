import SwiftUI

struct PasswordListView: View {
    let themeColor: Color
    @Binding var items: [PasswordItem]  // Now specific storage is owned by parent
    @State private var searchText = ""

    // Inline Add Form State
    @State private var isAdding = false
    @State private var newName = ""
    @State private var newUrl = ""
    @State private var newUsername = ""
    @State private var newPassword = ""

    // No init needed; binding passed in directly

    // Derived items based on search
    var filteredItems: [PasswordItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Search passwords...", text: $searchText)
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
            VStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    PasswordRow(
                        item: item,
                        onDelete: {
                            deleteItem(item)
                        }
                    )
                    .transition(.opacity.combined(with: .scale))
                }

                // Inline Add Form / Button
                VStack(spacing: 0) {
                    if isAdding {
                        VStack(spacing: 12) {
                            Text("New Password")
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
                                    newName.isEmpty || newUsername.isEmpty || newPassword.isEmpty
                                )
                                .opacity(
                                    newName.isEmpty || newUsername.isEmpty || newPassword.isEmpty
                                        ? 0.5 : 1.0)
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                        .cornerRadius(16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
        .padding(.horizontal, 10)
        .animation(.spring(), value: items)
        .animation(.spring(), value: isAdding)
    }

    private func deleteItem(_ item: PasswordItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }

    private func saveNewItem() {
        let randomColor =
            [Color.red, Color.blue, Color.green, Color.orange, Color.purple].randomElement()
            ?? .blue
        let initial = newName.first.map { String($0).uppercased() } ?? "?"

        let newItem = PasswordItem(
            name: newName,
            username: newUsername,
            password: newPassword,
            websiteUrl: newUrl,
            brandColor: randomColor,
            iconInitial: initial
        )

        withAnimation {
            items.append(newItem)
            isAdding = false
            cleanupForm()
        }
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

// Helper for inputs
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

struct PasswordListView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            PasswordListView(
                themeColor: .blue, items: .constant(PasswordItem.mockData(for: .personal)))
        }
    }
}

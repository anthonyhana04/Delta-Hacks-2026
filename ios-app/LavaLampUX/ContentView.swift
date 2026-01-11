import SwiftUI

enum AppState {
    case login
    case mainApp
}

struct ContentView: View {
    @StateObject private var authManager = AuthManager()

    var body: some View {
        ZStack {
            if !authManager.isLoggedIn {
                LoginView()
                    .transition(.opacity)
            } else {
                VaultView()
                    .transition(.move(edge: .trailing))
            }
        }
        .environmentObject(authManager)
        .animation(.easeInOut, value: authManager.isLoggedIn)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

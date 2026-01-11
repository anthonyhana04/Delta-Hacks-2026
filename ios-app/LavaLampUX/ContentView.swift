import SwiftUI

enum AppState {
    case login
    case mainApp
}

struct ContentView: View {
    @State private var appState: AppState = .login
    
    var body: some View {
        ZStack {
            switch appState {
            case .login:
                LoginView(onLoginSuccess: {
                    withAnimation {
                        appState = .mainApp
                    }
                })
                .transition(.opacity)
                
            case .mainApp:
                VaultView()
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

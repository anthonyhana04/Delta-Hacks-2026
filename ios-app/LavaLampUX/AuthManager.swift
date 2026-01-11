import Combine
import GoogleSignIn
import SwiftUI
import UIKit

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?

    // NOTE: This Client ID is for the iOS App.
    // Ensure this matches the one in Google Cloud Console and your Info.plist
    private let clientID =
        "298946968148-nrp0n4vuperdcifgbkjnjgrg4sjvuoap.apps.googleusercontent.com"
    private let backendURL = "\(APIConfig.baseURL)/auth/google"

    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController
        else {
            print("Root View Controller not found")
            return
        }

        // GIDConfiguration is sometimes optional depending on version,
        // but explicit configuration helps if Info.plist isn't perfect.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) {
            [weak self] result, error in
            if let error = error {
                print("Google Sign-In Error: \(error.localizedDescription)")
                self?.errorMessage = "Sign In Error: " + error.localizedDescription
                return
            }

            guard let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                print("Error: ID Token not found")
                self?.errorMessage = "ID Token missing"
                return
            }

            print("Google ID Token obtained. Sending to backend...")
            self?.sendTokenToBackend(idToken: idToken)
        }
    }

    private func sendTokenToBackend(idToken: String) {
        guard let url = URL(string: backendURL) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["id_token": idToken]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Backend Error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.errorMessage = "No response from backend"
                    return
                }

                if httpResponse.statusCode == 200 {
                    print("Backend Login Successful")
                    self?.isLoggedIn = true
                } else {
                    self?.errorMessage = "Backend failed with status: \(httpResponse.statusCode)"
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Backend Response: \(responseString)")
                    }
                }
            }
        }.resume()
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.errorMessage = nil
            print("User signed out successfully")
        }
    }
}

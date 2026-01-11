//
//  LavaLampUXApp.swift
//  LavaLampUX
//
//  Created by Seoa Mo on 2026-01-10.
//

import GoogleSignIn
import SwiftUI

@main
struct LavaLampUXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

//
//  KrypticGrindApp.swift
//  KrypticGrind
//
//  Created by akhil on 29/06/25.
//

import SwiftUI

@main
struct KrypticGrindApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}

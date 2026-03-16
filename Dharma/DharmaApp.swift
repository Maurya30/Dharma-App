//
//  DharmaApp.swift
//  Dharma
//
//  Created by Maurya Panchal on 2026-03-14.
//

import SwiftUI

@main
struct DharmaApp: App {
    @StateObject private var store = ScriptureStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

//
//  DiffinityApp.swift
//  Diffinity
//
//  Created by Egecan Kahyaoglu on 01.05.25.
//

import SwiftUI
import AppKit

@main
struct DiffinityApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .background(WindowAccessor())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Toggle Dark Mode") {
                    isDarkMode.toggle()
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Window Accessor
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

//
//  ContentView.swift
//  Diffinity
//
//  Created by Egecan Kahyaoglu on 01.05.25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var leftText = "Enter text to compare..."
    @State private var rightText = "Enter text to compare..."
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isChecking = false
    @State private var diffStats = DiffStats()
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .headerView, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    if isChecking {
                        HStack(spacing: 16) {
                            Label("\(diffStats.removals) removals", systemImage: "minus.circle.fill")
                                .foregroundColor(.red)
                            Label("\(diffStats.additions) additions", systemImage: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("\(diffStats.totalLines) lines")
                                .foregroundColor(.secondary)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isChecking.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isChecking ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isChecking ? "Checking..." : "Check Differences")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("R", modifiers: [.command])
                    
                    ThemeToggleButton(isDarkMode: $isDarkMode)
                        .padding(.leading, 8)
                }
                .padding()
                
                HStack(spacing: 0) {
                    DiffTextView(
                        text: $leftText,
                        comparisonText: $rightText,
                        side: .left,
                        isChecking: $isChecking,
                        diffStats: $diffStats
                    )
                    Divider()
                        .background(Color(NSColor.separatorColor))
                    DiffTextView(
                        text: $rightText,
                        comparisonText: $leftText,
                        side: .right,
                        isChecking: $isChecking,
                        diffStats: $diffStats
                    )
                }
                .padding()
            }
        }
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}

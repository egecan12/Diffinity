//
//  ContentView.swift
//  Diffinity
//
//  Created by Egecan Kahyaoglu on 01.05.25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var leftText = ""
    @State private var rightText = ""
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isChecking = false
    @State private var diffStats = DiffStats()
    @State private var documentTitle = "Welcome to Diffinity, your offline diff checker"
    
    // Sample texts for testing
    private let sampleLeftText = "hi this is a\ntest document"
    private let sampleRightText = "hii this is an\ntest document"
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .headerView, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content moved to the top for more space
                VStack(spacing: 0) {
                    HStack {
                        Text("Original text")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        Text("Changed text")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    
                    HStack(spacing: 0) {
                        // Original text editor
                        VStack {
                            TextEditor(text: $leftText)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                        }
                        .frame(minHeight: 200)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        
                        Spacer()
                            .frame(width: 10)
                        
                        // Changed text editor
                        VStack {
                            TextEditor(text: $rightText)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                        }
                        .frame(minHeight: 200)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                }
                .padding()
                
                // Diff summary view - with more space
                if isChecking {
                    DiffSummaryView(
                        leftText: $leftText,
                        rightText: $rightText,
                        isChecking: $isChecking
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .transition(.opacity)
                    .frame(maxHeight: .infinity) // Allow it to take more space
                }
                
                // Bottom section with logo and controls
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        // Icon image moved to the bottom
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        
                        Spacer()
                        
                        // Controls
                        HStack(spacing: 12) {
                            Button(action: {
                                leftText = ""
                                rightText = ""
                                isChecking = false
                            }) {
                                Text("Clear")
                                    .frame(width: 80)
                                    .padding(.vertical, 8)
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ThemeToggleButton(isDarkMode: $isDarkMode)
                            
                            // Bottom action button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // First reset isChecking to hide the current diff view
                                    isChecking = false
                                    
                                    // If both text fields are empty, load sample text for testing
                                    if leftText.isEmpty && rightText.isEmpty {
                                        leftText = sampleLeftText
                                        rightText = sampleRightText
                                    }
                                    
                                    // Wait for the animation to complete before showing results
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isChecking = true
                                        }
                                    }
                                }
                            }) {
                                Text("Check Differences")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 180)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("R", modifiers: [.command])
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
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

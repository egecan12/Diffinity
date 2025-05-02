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
    @State private var documentTitle = "Untitled diff"
    
    // Sample texts for testing
    private let sampleLeftText = "hi this is a\ntest document"
    private let sampleRightText = "hii this is an\ntest document"
    
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .headerView, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with title and controls
                VStack {
                    Text(documentTitle)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    HStack {
                        Button(action: {
                            leftText = "Enter text to compare..."
                            rightText = "Enter text to compare..."
                            isChecking = false
                        }) {
                            Text("Clear")
                                .frame(width: 80)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            // Save action would go here
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .frame(width: 100)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            // Load sample text for testing
                            leftText = sampleLeftText
                            rightText = sampleRightText
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(width: 100)
                            .padding(.vertical, 8)
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        ThemeToggleButton(isDarkMode: $isDarkMode)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Diff summary view
                if isChecking {
                    DiffSummaryView(
                        leftText: $leftText,
                        rightText: $rightText,
                        isChecking: $isChecking
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .transition(.opacity)
                }
                
                // Main content
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
                            if leftText == "Enter text to compare..." {
                                TextEditor(text: $leftText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .onTapGesture {
                                        if leftText == "Enter text to compare..." {
                                            leftText = ""
                                        }
                                    }
                            } else {
                                TextEditor(text: $leftText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                            }
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
                            if rightText == "Enter text to compare..." {
                                TextEditor(text: $rightText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                                    .onTapGesture {
                                        if rightText == "Enter text to compare..." {
                                            rightText = ""
                                        }
                                    }
                            } else {
                                TextEditor(text: $rightText)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(8)
                            }
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
                
                // Bottom action button
                Button(action: {
                    withAnimation {
                        // If both text fields have placeholder text, load sample text for testing
                        if leftText == "Enter text to compare..." && rightText == "Enter text to compare..." {
                            leftText = sampleLeftText
                            rightText = sampleRightText
                            // Wait a moment before checking
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isChecking = true
                            }
                        } else {
                            isChecking = true  // Always set to true to trigger diff check
                        }
                    }
                }) {
                    Text("Find difference")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 180)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("R", modifiers: [.command])
                .padding(.bottom, 16)
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

import SwiftUI
import AppKit

struct DiffSummaryView: View {
    @Binding var leftText: String
    @Binding var rightText: String
    @Binding var isChecking: Bool
    
    @State private var diffLines: [DiffLineDisplay] = []
    @State private var removals: Int = 0
    @State private var additions: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if isChecking {
                // Header with stats
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                        Text("\(removals) removals")
                            .foregroundColor(.primary)
                            .font(.system(size: 15, weight: .medium))
                        
                        Text("Copy")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Text("\(additions) additions")
                            .foregroundColor(.primary)
                            .font(.system(size: 15, weight: .medium))
                        
                        Text("Copy")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                if diffLines.isEmpty {
                    Text("No differences found")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .padding()
                } else {
                    // Diff content
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(diffLines) { diffLine in
                                DiffLineView(diffLine: diffLine)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .onChange(of: isChecking) { newValue in
            if newValue {
                computeDiff()
            }
        }
        .onChange(of: leftText) { _ in
            if isChecking {
                computeDiff()
            }
        }
        .onChange(of: rightText) { _ in
            if isChecking {
                computeDiff()
            }
        }
        .onAppear {
            if isChecking {
                computeDiff()
            }
        }
    }
    
    private func computeDiff() {
        // Don't compute if either text is just the placeholder
        if leftText == "Enter text to compare..." || rightText == "Enter text to compare..." {
            diffLines = []
            removals = 0
            additions = 0
            return
        }
        
        let result = DiffHighlighter.computeDiff(between: leftText, and: rightText)
        
        var displayLines: [DiffLineDisplay] = []
        var addCount = 0
        var removeCount = 0
        
        for line in result.lines {
            if line.type == .added {
                addCount += 1
                displayLines.append(DiffLineDisplay(
                    id: line.id,
                    leftLineNumber: 0,
                    rightLineNumber: line.lineNumber,
                    leftText: "",
                    rightText: line.text,
                    changes: line.changes,
                    type: .added
                ))
            } else if line.type == .removed {
                removeCount += 1
                displayLines.append(DiffLineDisplay(
                    id: line.id,
                    leftLineNumber: line.lineNumber,
                    rightLineNumber: 0,
                    leftText: line.text,
                    rightText: "",
                    changes: line.changes,
                    type: .removed
                ))
            }
        }
        
        self.diffLines = displayLines
        self.removals = removeCount
        self.additions = addCount
    }
}

struct DiffLineDisplay: Identifiable {
    let id: UUID
    let leftLineNumber: Int
    let rightLineNumber: Int
    let leftText: String
    let rightText: String
    let changes: [CharacterChange]
    let type: DiffLineType
}

struct DiffLineView: View {
    let diffLine: DiffLineDisplay
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side
            if diffLine.type == .removed {
                HStack(spacing: 4) {
                    Text("\(diffLine.leftLineNumber)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)
                        .padding(.leading, 16)
                    
                    Text(diffLine.leftText)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Right side
            if diffLine.type == .added {
                HStack(spacing: 4) {
                    Text("\(diffLine.rightLineNumber)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .trailing)
                        .padding(.leading, 16)
                    
                    Text(diffLine.rightText)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 36)
    }
}

#Preview {
    DiffSummaryView(
        leftText: .constant("hi this is a\ntest document"),
        rightText: .constant("hii this is an\ntest document"),
        isChecking: .constant(true)
    )
    .frame(width: 600)
    .padding()
} 
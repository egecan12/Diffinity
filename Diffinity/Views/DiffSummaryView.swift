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
            if isChecking && !diffLines.isEmpty {
                HStack {
                    Label("\(removals) removals", systemImage: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Copy")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Label("\(additions) additions", systemImage: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Copy")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(diffLines) { diffLine in
                            DiffLineView(diffLine: diffLine)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 150)
            } else if isChecking {
                Text("No differences found")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                    .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
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
        
        // Debug output
        print("Diff computed: \(removeCount) removals, \(addCount) additions")
        print("Left text: \(leftText)")
        print("Right text: \(rightText)")
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
        HStack(alignment: .top, spacing: 0) {
            // Left line number and text
            HStack(spacing: 0) {
                Text(diffLine.leftLineNumber > 0 ? "\(diffLine.leftLineNumber)" : "")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
                    .padding(.trailing, 8)
                
                if diffLine.type == .removed {
                    Text(diffLine.leftText)
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(width: 250, alignment: .leading)
            .padding(.horizontal, 4)
            
            // Right line number and text
            HStack(spacing: 0) {
                Text(diffLine.rightLineNumber > 0 ? "\(diffLine.rightLineNumber)" : "")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
                    .padding(.trailing, 8)
                
                if diffLine.type == .added {
                    Text(diffLine.rightText)
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(width: 250, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 2)
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
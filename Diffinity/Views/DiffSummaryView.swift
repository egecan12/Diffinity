import SwiftUI
import AppKit

struct DiffSummaryView: View {
    @Binding var leftText: String
    @Binding var rightText: String
    @Binding var isChecking: Bool
    
    @State private var diffPairs: [DiffPair] = []
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
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Text("\(additions) additions")
                            .foregroundColor(.primary)
                            .font(.system(size: 15, weight: .medium))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                if diffPairs.isEmpty {
                    Text("No differences found")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .padding()
                } else {
                    // Column Headers
                    HStack {
                        Text("Original Text")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 40)
                        
                        Text("Modified Text")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    Divider()
                    
                    // Diff content
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(diffPairs) { pair in
                                DiffLineComparisonView(pair: pair)
                            }
                        }
                    }
                    .frame(maxHeight: 400)
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
                // Clear previous results first
                diffPairs = []
                removals = 0
                additions = 0
                
                // Force a slight delay to ensure UI updates
                DispatchQueue.main.async {
                    computeDiff()
                }
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
            diffPairs = []
            removals = 0
            additions = 0
            return
        }
        
        let result = DiffHighlighter.computeDiff(between: leftText, and: rightText)
        
        // Count statistics
        let addedLines = result.lines.filter { $0.type == .added }.count
        let removedLines = result.lines.filter { $0.type == .removed }.count
        
        // Create line pairs by matching up corresponding lines
        var pairs: [DiffPair] = []
        let leftLines = leftText.components(separatedBy: .newlines)
        let rightLines = rightText.components(separatedBy: .newlines)
        
        // Create a mapping of line numbers to types
        var leftLineTypes: [Int: DiffLineType] = [:]
        var rightLineTypes: [Int: DiffLineType] = [:]
        var leftLineChanges: [Int: [CharacterChange]] = [:]
        var rightLineChanges: [Int: [CharacterChange]] = [:]
        
        // Extract line type information
        for line in result.lines {
            if line.lineNumber > 0 {
                if line.type == .removed || line.type == .modified {
                    leftLineTypes[line.lineNumber] = line.type
                    leftLineChanges[line.lineNumber] = line.changes
                } else if line.type == .added {
                    rightLineTypes[line.lineNumber] = line.type
                    rightLineChanges[line.lineNumber] = line.changes
                } else if line.type == .unchanged {
                    // Unchanged lines are present in both
                    leftLineTypes[line.lineNumber] = line.type
                    rightLineTypes[line.lineNumber] = line.type
                }
            }
        }
        
        // Get the maximum line count
        let maxLines = max(leftLines.count, rightLines.count)
        
        // Create pairs for each line
        for i in 0..<maxLines {
            let leftLine = i < leftLines.count ? leftLines[i] : ""
            let rightLine = i < rightLines.count ? rightLines[i] : ""
            
            let leftLineNumber = i + 1
            let rightLineNumber = i + 1
            
            let leftType = leftLineTypes[leftLineNumber] ?? .unchanged
            let rightType = rightLineTypes[rightLineNumber] ?? .unchanged
            
            // Determine the type for the pair
            var pairType: DiffLineType = .unchanged
            if leftType == .removed && rightType == .added {
                pairType = .modified
            } else if leftType == .removed {
                pairType = .removed
            } else if rightType == .added {
                pairType = .added
            } else if leftType == .modified || rightType == .modified {
                pairType = .modified
            }
            
            pairs.append(DiffPair(
                id: UUID(),
                leftLineNumber: leftLine.isEmpty ? 0 : leftLineNumber,
                rightLineNumber: rightLine.isEmpty ? 0 : rightLineNumber,
                leftText: leftLine,
                rightText: rightLine,
                leftChanges: leftLineChanges[leftLineNumber] ?? [],
                rightChanges: rightLineChanges[rightLineNumber] ?? [],
                type: pairType
            ))
        }
        
        self.diffPairs = pairs
        self.removals = removedLines
        self.additions = addedLines
    }
}

struct DiffPair: Identifiable {
    let id: UUID
    let leftLineNumber: Int
    let rightLineNumber: Int
    let leftText: String
    let rightText: String
    let leftChanges: [CharacterChange]
    let rightChanges: [CharacterChange]
    let type: DiffLineType
}

struct DiffLineComparisonView: View {
    let pair: DiffPair
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side
            HStack(spacing: 4) {
                Text(pair.leftLineNumber > 0 ? "\(pair.leftLineNumber)" : " ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 25, alignment: .trailing)
                
                if !pair.leftText.isEmpty {
                    HighlightedText(
                        text: pair.leftText,
                        changes: pair.leftChanges,
                        lineType: pair.type == .removed || pair.type == .modified ? pair.type : .unchanged
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(
                pair.type == .removed ? Color.red.opacity(0.1) :
                (pair.type == .modified ? Color.orange.opacity(0.1) : Color.clear)
            )
            
            // Right side
            HStack(spacing: 4) {
                Text(pair.rightLineNumber > 0 ? "\(pair.rightLineNumber)" : " ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 25, alignment: .trailing)
                
                if !pair.rightText.isEmpty {
                    HighlightedText(
                        text: pair.rightText,
                        changes: pair.rightChanges,
                        lineType: pair.type == .added || pair.type == .modified ? pair.type : .unchanged
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .background(
                pair.type == .added ? Color.green.opacity(0.1) :
                (pair.type == .modified ? Color.orange.opacity(0.1) : Color.clear)
            )
        }
        .padding(.horizontal)
        
        Divider()
    }
}

struct HighlightedText: View {
    let text: String
    let changes: [CharacterChange]
    let lineType: DiffLineType
    
    var body: some View {
        Text(attributedString)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        // Default appearance
        attributedString.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        attributedString.foregroundColor = .primary
        
        // Apply highlights only to the changed portions
        for change in changes {
            if let range = Range(NSRange(location: change.range.location, length: change.range.length), in: attributedString) {
                let foregroundColor: Color
                let backgroundColorOpacity: CGFloat = 0.3
                let backgroundColor: Color
                
                switch change.type {
                case .added:
                    foregroundColor = .green
                    backgroundColor = Color.green.opacity(backgroundColorOpacity)
                case .removed:
                    foregroundColor = .red
                    backgroundColor = Color.red.opacity(backgroundColorOpacity)
                case .modified:
                    foregroundColor = .orange
                    backgroundColor = Color.orange.opacity(backgroundColorOpacity)
                default:
                    foregroundColor = .primary
                    backgroundColor = .clear
                }
                
                attributedString[range].foregroundColor = foregroundColor
                attributedString[range].backgroundColor = backgroundColor
            }
        }
        
        return attributedString
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
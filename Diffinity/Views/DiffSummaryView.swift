import SwiftUI
import AppKit

struct DiffSummaryView: View {
    @Binding var leftText: String
    @Binding var rightText: String
    @Binding var isChecking: Bool
    
    @State private var diffLines: [DiffLineDisplay] = []
    @State private var removals: Int = 0
    @State private var additions: Int = 0
    @State private var modifications: Int = 0
    
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
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                        Text("\(modifications) modifications")
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
                                FullTextDiffView(diffLine: diffLine)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
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
            modifications = 0
            return
        }
        
        let result = DiffHighlighter.computeDiff(between: leftText, and: rightText)
        
        var displayLines: [DiffLineDisplay] = []
        var addCount = 0
        var removeCount = 0
        var modifyCount = 0
        
        let leftLines = leftText.components(separatedBy: .newlines)
        let rightLines = rightText.components(separatedBy: .newlines)
        
        var processedLeftIndexes = Set<Int>()
        var processedRightIndexes = Set<Int>()
        
        // First, process the diff lines to create our display lines
        for line in result.lines {
            if line.type == .added {
                addCount += 1
                processedRightIndexes.insert(line.lineNumber - 1)
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
                processedLeftIndexes.insert(line.lineNumber - 1)
                displayLines.append(DiffLineDisplay(
                    id: line.id,
                    leftLineNumber: line.lineNumber,
                    rightLineNumber: 0,
                    leftText: line.text,
                    rightText: "",
                    changes: line.changes,
                    type: .removed
                ))
            } else if line.type == .unchanged {
                processedLeftIndexes.insert(line.lineNumber - 1)
                
                // Find matching line in right text
                if line.lineNumber - 1 < leftLines.count {
                    let leftLineText = leftLines[line.lineNumber - 1]
                    let rightLineIndex = rightLines.firstIndex(of: leftLineText) ?? -1
                    
                    if rightLineIndex >= 0 {
                        processedRightIndexes.insert(rightLineIndex)
                        displayLines.append(DiffLineDisplay(
                            id: line.id,
                            leftLineNumber: line.lineNumber,
                            rightLineNumber: rightLineIndex + 1,
                            leftText: leftLineText,
                            rightText: leftLineText,
                            changes: [],
                            type: .unchanged
                        ))
                    }
                }
            }
        }
        
        // Add remaining lines that might have modifications
        for (leftIndex, leftLine) in leftLines.enumerated() {
            if !processedLeftIndexes.contains(leftIndex) {
                for (rightIndex, rightLine) in rightLines.enumerated() {
                    if !processedRightIndexes.contains(rightIndex) {
                        // These are potentially modified versions of each other
                        let changes = findChanges(oldLine: leftLine, newLine: rightLine)
                        if !changes.isEmpty {
                            modifyCount += 1
                            processedLeftIndexes.insert(leftIndex)
                            processedRightIndexes.insert(rightIndex)
                            
                            displayLines.append(DiffLineDisplay(
                                id: UUID(),
                                leftLineNumber: leftIndex + 1,
                                rightLineNumber: rightIndex + 1,
                                leftText: leftLine,
                                rightText: rightLine,
                                changes: changes,
                                type: .modified
                            ))
                            break
                        }
                    }
                }
            }
        }
        
        // Sort by line numbers
        displayLines.sort { 
            if $0.leftLineNumber != 0 && $1.leftLineNumber != 0 {
                return $0.leftLineNumber < $1.leftLineNumber
            } else if $0.rightLineNumber != 0 && $1.rightLineNumber != 0 {
                return $0.rightLineNumber < $1.rightLineNumber
            } else {
                return ($0.leftLineNumber > 0 ? $0.leftLineNumber : $0.rightLineNumber) < 
                       ($1.leftLineNumber > 0 ? $1.leftLineNumber : $1.rightLineNumber)
            }
        }
        
        self.diffLines = displayLines
        self.removals = removeCount
        self.additions = addCount
        self.modifications = modifyCount
    }
    
    private func findChanges(oldLine: String, newLine: String) -> [CharacterChange] {
        let oldChars = Array(oldLine)
        let newChars = Array(newLine)
        var changes: [CharacterChange] = []
        
        var startDiff = 0
        while startDiff < min(oldChars.count, newChars.count) && oldChars[startDiff] == newChars[startDiff] {
            startDiff += 1
        }
        
        var endDiff = 0
        while endDiff < min(oldChars.count - startDiff, newChars.count - startDiff) {
            let oldIndex = oldChars.count - 1 - endDiff
            let newIndex = newChars.count - 1 - endDiff
            if oldChars[oldIndex] != newChars[newIndex] {
                break
            }
            endDiff += 1
        }
        
        if startDiff < oldChars.count {
            changes.append(CharacterChange(
                range: NSRange(location: startDiff, length: oldChars.count - startDiff - endDiff),
                type: .removed
            ))
        }
        
        if startDiff < newChars.count {
            changes.append(CharacterChange(
                range: NSRange(location: startDiff, length: newChars.count - startDiff - endDiff),
                type: .modified
            ))
        }
        
        return changes
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

struct FullTextDiffView: View {
    let diffLine: DiffLineDisplay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 16) {
                // Left side
                HStack(spacing: 4) {
                    Text(diffLine.leftLineNumber > 0 ? "\(diffLine.leftLineNumber)" : " ")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .trailing)
                    
                    if !diffLine.leftText.isEmpty {
                        HighlightedText(
                            text: diffLine.leftText,
                            changes: diffLine.type == .removed || diffLine.type == .modified ? diffLine.changes.filter { $0.type == .removed } : [],
                            lineType: diffLine.type
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right side
                HStack(spacing: 4) {
                    Text(diffLine.rightLineNumber > 0 ? "\(diffLine.rightLineNumber)" : " ")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 25, alignment: .trailing)
                    
                    if !diffLine.rightText.isEmpty {
                        HighlightedText(
                            text: diffLine.rightText,
                            changes: diffLine.type == .added || diffLine.type == .modified ? diffLine.changes.filter { $0.type == .added || $0.type == .modified } : [],
                            lineType: diffLine.type
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            
            Divider()
        }
        .padding(.horizontal)
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
        
        // Apply the background color to the entire line if needed
        if lineType == .added || lineType == .removed || lineType == .modified {
            let backgroundColorOpacity: CGFloat = 0.1
            let backgroundColor: Color
            
            switch lineType {
            case .added:
                backgroundColor = Color.green.opacity(backgroundColorOpacity)
            case .removed:
                backgroundColor = Color.red.opacity(backgroundColorOpacity)
            case .modified:
                backgroundColor = Color.orange.opacity(backgroundColorOpacity)
            default:
                backgroundColor = Color.clear
            }
            
            if let range = Range(NSRange(location: 0, length: text.utf16.count), in: attributedString) {
                attributedString[range].backgroundColor = backgroundColor
            }
        }
        
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
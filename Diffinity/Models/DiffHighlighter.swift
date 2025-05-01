import Foundation
import SwiftUI

struct DiffResult {
    var lines: [DiffLine]
    var stats: DiffStats
}

struct DiffStats {
    var removals: Int
    var additions: Int
    var totalLines: Int
    
    init(removals: Int = 0, additions: Int = 0, totalLines: Int = 0) {
        self.removals = removals
        self.additions = additions
        self.totalLines = totalLines
    }
}

struct DiffLine: Identifiable {
    let id = UUID()
    let text: String
    let type: DiffLineType
    let lineNumber: Int
    let changes: [CharacterChange]
}

struct CharacterChange {
    let range: NSRange
    let type: DiffLineType
}

enum DiffLineType {
    case unchanged
    case added
    case removed
    
    var color: Color {
        switch self {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.15)
        case .removed:
            return Color.red.opacity(0.15)
        }
    }
    
    var textColor: Color {
        switch self {
        case .unchanged:
            return .primary
        case .added:
            return Color.green
        case .removed:
            return Color.red
        }
    }
}

class DiffHighlighter {
    static func computeDiff(between oldText: String, and newText: String) -> DiffResult {
        let oldLines = oldText.components(separatedBy: .newlines)
        let newLines = newText.components(separatedBy: .newlines)
        
        var result: [DiffLine] = []
        var stats = DiffStats()
        stats.totalLines = max(oldLines.count, newLines.count)
        
        var i = 0
        var j = 0
        
        while i < oldLines.count || j < newLines.count {
            if i < oldLines.count && j < newLines.count {
                if oldLines[i] == newLines[j] {
                    // Unchanged line
                    result.append(DiffLine(
                        text: oldLines[i],
                        type: .unchanged,
                        lineNumber: i + 1,
                        changes: []
                    ))
                    i += 1
                    j += 1
                } else {
                    // Find character-level differences
                    let changes = findCharacterChanges(
                        oldLine: oldLines[i],
                        newLine: newLines[j]
                    )
                    
                    // Removed line
                    result.append(DiffLine(
                        text: oldLines[i],
                        type: .removed,
                        lineNumber: i + 1,
                        changes: changes.filter { $0.type == .removed }
                    ))
                    stats.removals += 1
                    
                    // Added line
                    result.append(DiffLine(
                        text: newLines[j],
                        type: .added,
                        lineNumber: j + 1,
                        changes: changes.filter { $0.type == .added }
                    ))
                    stats.additions += 1
                    
                    i += 1
                    j += 1
                }
            } else if j < newLines.count {
                // Added line
                result.append(DiffLine(
                    text: newLines[j],
                    type: .added,
                    lineNumber: j + 1,
                    changes: []
                ))
                stats.additions += 1
                j += 1
            } else {
                // Removed line
                result.append(DiffLine(
                    text: oldLines[i],
                    type: .removed,
                    lineNumber: i + 1,
                    changes: []
                ))
                stats.removals += 1
                i += 1
            }
        }
        
        return DiffResult(lines: result, stats: stats)
    }
    
    private static func findCharacterChanges(oldLine: String, newLine: String) -> [CharacterChange] {
        var changes: [CharacterChange] = []
        
        let oldChars = Array(oldLine)
        let newChars = Array(newLine)
        
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
                type: .added
            ))
        }
        
        return changes
    }
} 
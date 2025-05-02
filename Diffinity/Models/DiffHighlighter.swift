import Foundation
import SwiftUI

struct DiffResult {
    var lines: [DiffLine]
    var stats: DiffStats
}

struct DiffStats {
    var removals: Int
    var additions: Int
    var modifications: Int
    var totalLines: Int
    
    init(removals: Int = 0, additions: Int = 0, modifications: Int = 0, totalLines: Int = 0) {
        self.removals = removals
        self.additions = additions
        self.modifications = modifications
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
    case modified
    
    var color: Color {
        switch self {
        case .unchanged:
            return .clear
        case .added:
            return Color.green.opacity(0.15)
        case .removed:
            return Color.red.opacity(0.15)
        case .modified:
            return Color.orange.opacity(0.15)
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
        case .modified:
            return Color.orange
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
                    
                    let hasSignificantChanges = changes.contains { $0.type != .unchanged }
                    let isSimilar = calcSimilarity(oldLines[i], newLines[j]) > 0.5
                    
                    if hasSignificantChanges && isSimilar {
                        // Lines are similar enough to be considered modified versions
                        stats.modifications += 1
                        
                        // Add a modified line with the old text and character-level changes
                        result.append(DiffLine(
                            text: oldLines[i],
                            type: .modified,
                            lineNumber: i + 1,
                            changes: changes.filter { $0.type == .removed }
                        ))
                        
                        // Also add the new version
                        result.append(DiffLine(
                            text: newLines[j],
                            type: .modified,
                            lineNumber: j + 1,
                            changes: changes.filter { $0.type == .added }
                        ))
                    } else {
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
                    }
                    
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
    
    private static func calcSimilarity(_ s1: String, _ s2: String) -> Double {
        let len1 = s1.count
        let len2 = s2.count
        
        if len1 == 0 || len2 == 0 {
            return 0.0
        }
        
        // Calculate common characters
        let set1 = Set(s1)
        let set2 = Set(s2)
        let common = set1.intersection(set2)
        
        // Calculate similarity based on common characters
        return Double(common.count) / Double(max(len1, len2))
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
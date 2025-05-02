import SwiftUI
import AppKit

struct DiffTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var comparisonText: String
    let side: DiffSide
    @Binding var isChecking: Bool
    @Binding var diffStats: DiffStats
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Create line numbers view
        let lineNumbersView = LineNumberView()
        lineNumbersView.translatesAutoresizingMaskIntoConstraints = false
        lineNumbersView.wantsLayer = true
        lineNumbersView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
        containerView.addSubview(lineNumbersView)
        
        // Create scroll view and text view
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.wantsLayer = true
        scrollView.layer?.cornerRadius = 12
        let textView = CustomTextView()
        
        // Configure text view
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.backgroundColor = .clear
        
        // Add modern placeholder text style
        if textView.string.isEmpty {
            textView.textStorage?.append(NSAttributedString(
                string: "Enter text to compare...",
                attributes: [
                    .foregroundColor: NSColor.placeholderTextColor,
                    .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                ]
            ))
        }
        
        // Configure scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        
        containerView.addSubview(scrollView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            lineNumbersView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineNumbersView.topAnchor.constraint(equalTo: containerView.topAnchor),
            lineNumbersView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            lineNumbersView.widthAnchor.constraint(equalToConstant: 40),
            
            scrollView.leadingAnchor.constraint(equalTo: lineNumbersView.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Set up line numbers view
        lineNumbersView.textView = textView
        
        // Store references in coordinator
        context.coordinator.textView = textView
        context.coordinator.lineNumbersView = lineNumbersView
        
        return containerView
    }
    
    func updateNSView(_ containerView: NSView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        // Update container appearance based on theme
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        if !context.coordinator.isEditing && textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
            if isChecking {
                highlightDifferences(in: textView)
            } else {
                clearHighlighting(in: textView)
            }
            context.coordinator.lineNumbersView?.needsDisplay = true
        }
    }
    
    private func highlightDifferences(in textView: NSTextView) {
        let diffResult = DiffHighlighter.computeDiff(between: text, and: comparisonText)
        diffStats = diffResult.stats
        
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        attributedString.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        ], range: fullRange)
        
        for line in diffResult.lines where line.type != .unchanged {
            let range = (text as NSString).range(of: line.text)
            if range.location != NSNotFound {
                var backgroundColor: NSColor
                
                switch line.type {
                case .removed:
                    backgroundColor = NSColor.systemRed.withAlphaComponent(0.15)
                case .added:
                    backgroundColor = NSColor.systemGreen.withAlphaComponent(0.15)
                case .modified:
                    backgroundColor = NSColor.systemOrange.withAlphaComponent(0.15)
                default:
                    backgroundColor = NSColor.clear
                }
                
                attributedString.addAttribute(.backgroundColor, value: backgroundColor, range: range)
                
                for change in line.changes {
                    let changeRange = NSRange(
                        location: range.location + change.range.location,
                        length: change.range.length
                    )
                    
                    if changeRange.location + changeRange.length <= text.utf16.count {
                        var foregroundColor: NSColor
                        
                        switch change.type {
                        case .removed:
                            foregroundColor = NSColor.systemRed
                        case .added:
                            foregroundColor = NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1.0)
                        case .modified:
                            foregroundColor = NSColor.systemOrange
                        default:
                            foregroundColor = NSColor.labelColor
                        }
                        
                        attributedString.addAttributes([
                            .foregroundColor: foregroundColor,
                            .backgroundColor: backgroundColor.withAlphaComponent(0.3)
                        ], range: changeRange)
                    }
                }
            }
        }
        
        textView.textStorage?.setAttributedString(attributedString)
    }
    
    private func clearHighlighting(in textView: NSTextView) {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        attributedString.addAttributes([
            .foregroundColor: NSColor.labelColor,
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        ], range: fullRange)
        
        textView.textStorage?.setAttributedString(attributedString)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DiffTextView
        var isEditing = false
        weak var textView: NSTextView?
        weak var lineNumbersView: LineNumberView?
        
        init(_ parent: DiffTextView) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }
        
        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
            if let textView = notification.object as? NSTextView {
                updateText(from: textView)
            }
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateText(from: textView)
            lineNumbersView?.needsDisplay = true
        }
        
        private func updateText(from textView: NSTextView) {
            let currentRange = textView.selectedRange()
            let visibleRect = textView.visibleRect
            
            parent.text = textView.string
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if self.parent.isChecking {
                    self.parent.highlightDifferences(in: textView)
                } else {
                    self.parent.clearHighlighting(in: textView)
                }
                
                if currentRange.location <= textView.string.count {
                    textView.setSelectedRange(currentRange)
                    textView.scrollToVisible(visibleRect)
                }
            }
        }
    }
}

class CustomTextView: NSTextView {
    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
    }
    
    override var frame: NSRect {
        didSet {
            backgroundColor = .clear
        }
    }
}

class LineNumberView: NSView {
    weak var textView: NSTextView?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let textView = textView else { return }
        
        let text = textView.string
        let lineCount = text.components(separatedBy: .newlines).count
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        for i in 1...lineCount {
            let lineNumber = "\(i)"
            let lineNumberSize = lineNumber.size(withAttributes: attributes)
            let y = CGFloat(i - 1) * lineNumberSize.height + 12
            
            lineNumber.draw(
                at: NSPoint(x: bounds.width - lineNumberSize.width - 8, y: y),
                withAttributes: attributes
            )
        }
    }
}

enum DiffSide {
    case left
    case right
}

#Preview {
    DiffTextView(
        text: .constant("Hello, World!\nThis is a test."),
        comparisonText: .constant("Hello, Swift!\nThis is a test."),
        side: .left,
        isChecking: .constant(false),
        diffStats: .constant(DiffStats())
    )
} 
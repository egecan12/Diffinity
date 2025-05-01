import SwiftUI

struct ThemeToggleButton: View {
    @Binding var isDarkMode: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDarkMode.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(isDarkMode ? "Dark Mode" : "Light Mode")
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
    }
}

#Preview {
    ThemeToggleButton(isDarkMode: .constant(false))
        .padding()
} 
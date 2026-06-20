import SwiftUI

struct ToastView: View {
    let input: String?
    let output: String
    let isMessageOnly: Bool

    /// Create a toast with input → output format.
    init(input: String, output: String) {
        self.input = input
        self.output = output
        self.isMessageOnly = false
    }

    /// Create a toast with only a message (no arrow format).
    init(message: String) {
        self.input = nil
        self.output = message
        self.isMessageOnly = true
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)

            if isMessageOnly {
                Text(output)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.primary)
            } else {
                Text("\(input ?? "") → \(output)")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        // Original background style (.ultraThinMaterial) inside rounded rect;
        // outside the rounded rect the window is fully transparent
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isMessageOnly ? output : "\(input ?? "") 转换为 \(output)")
    }
}

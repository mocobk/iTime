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
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if isMessageOnly {
                Text(output)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("\(truncatedInput) → \(output)")
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isMessageOnly ? output : "\(input ?? "") 转换为 \(output)")
    }

    private var truncatedInput: String {
        guard let input else { return "" }
        if input.count > 20 {
            return String(input.prefix(17)) + "..."
        }
        return input
    }
}

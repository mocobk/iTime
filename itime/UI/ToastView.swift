import SwiftUI

struct ToastView: View {
    let input: String
    let output: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Text("\(truncatedInput) → \(output)")
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(input) 转换为 \(output)")
    }

    private var truncatedInput: String {
        if input.count > 20 {
            return String(input.prefix(17)) + "..."
        }
        return input
    }
}

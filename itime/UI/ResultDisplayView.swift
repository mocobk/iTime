import SwiftUI
import AppKit

@MainActor
struct ResultDisplayView: View {
    let result: ConversionResult
    @State private var copiedField: String?
    @State private var copyTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Direction label
            HStack(spacing: 4) {
                Image(systemName: result.direction == .timestampToDate
                      ? "number.arrow.right.calendar"
                      : "calendar.arrow.right.number")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(result.direction == .timestampToDate
                     ? "时间戳 → 日期"
                     : "日期 → 时间戳")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Primary result
            resultRow(
                label: primaryLabel,
                value: result.output,
                fieldKey: "primary"
            )

            // Secondary result (only for date → timestamp)
            if let secondary = result.secondaryOutput {
                resultRow(
                    label: secondaryLabel,
                    value: secondary,
                    fieldKey: "secondary"
                )
            }

            // Original input (subtle)
            Text(result.input)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary.opacity(0.3))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("转换结果: \(result.output)")
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func resultRow(label: String, value: String, fieldKey: String) -> some View {
        HStack {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }

            Text(value)
                .font(.system(result.direction == .timestampToDate ? .title3 : .title2, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Copy button
            Button {
                copyValue(value, fieldKey: fieldKey)
            } label: {
                Image(systemName: copiedField == fieldKey ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 14))
                    .foregroundStyle(copiedField == fieldKey ? .green : .secondary)
                    .symbolEffect(.bounce, value: copiedField == fieldKey)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copiedField == fieldKey ? "已复制" : "复制\(label)")
        }
    }

    // MARK: - Labels

    private var primaryLabel: String {
        if result.direction == .dateToTimestamp {
            return result.outputPrecision.displayName
        }
        return ""
    }

    private var secondaryLabel: String {
        // Secondary is always the opposite precision
        let opposite: OutputPrecision = result.outputPrecision == .seconds ? .milliseconds : .seconds
        return opposite.displayName
    }

    // MARK: - Copy

    private func copyValue(_ value: String, fieldKey: String) {
        ClipboardService.shared.writeText(value)
        withAnimation {
            copiedField = fieldKey
        }
        copyTask?.cancel()
        copyTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled {
                withAnimation {
                    copiedField = nil
                }
            }
        }
    }
}

import SwiftUI

@MainActor
struct HistoryListView: View {
    @Environment(ConversionHistory.self) private var history

    var body: some View {
        VStack(spacing: 0) {
            if history.isEmpty {
                emptyState
                    .padding(.vertical, 20)
            } else {
                headerView
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(history.entries) { entry in
                            HistoryRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("暂无转换记录")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerView: some View {
        HStack {
            Text("历史记录")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                history.clear()
            } label: {
                Text("清除")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("清除历史记录")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

@MainActor
struct HistoryRowView: View {
    let entry: ConversionResult
    @State private var copied = false

    var body: some View {
        Button {
            ClipboardService.shared.writeText(entry.output)
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation { copied = false }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: entry.direction == .timestampToDate
                      ? "number" : "calendar")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)

                Text(entry.input)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Text(entry.output)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if copied {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(entry.input) 转换为 \(entry.output)")
    }

    private var relativeTime: String {
        let interval = Date.now.timeIntervalSince(entry.createdAt)
        if interval < 60 { return "刚刚" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        if interval < 86400 { return "\(Int(interval / 3600))小时前" }
        return "\(Int(interval / 86400))天前"
    }
}

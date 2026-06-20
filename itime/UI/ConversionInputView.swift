import SwiftUI

struct ConversionInputView: View {
    @Binding var text: String
    let classification: InputClassification
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("输入时间戳或日期...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, design: .monospaced))
                    .focused($isFocused)
                    .accessibilityLabel("时间转换输入框")

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("清除输入")
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary.opacity(0.5))
            )

            // Type indicator
            if !text.isEmpty {
                typeIndicator
                    .transition(.opacity)
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    @ViewBuilder
    private var typeIndicator: some View {
        HStack(spacing: 4) {
            switch classification {
            case .unixTimestamp(let unit):
                Label {
                    Text("时间戳(\(unit.displayName)) → 日期")
                } icon: {
                    Image(systemName: "number")
                }
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.quaternary))

            case .dateString(let format):
                Label {
                    Text("日期 → 时间戳")
                } icon: {
                    Image(systemName: "calendar")
                }
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(.quaternary))

            case .unrecognized:
                if text.count >= 3 {
                    Label {
                        Text("无法识别时间格式")
                    } icon: {
                        Image(systemName: "questionmark.circle")
                    }
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.quaternary))
                }
            }
        }
    }
}

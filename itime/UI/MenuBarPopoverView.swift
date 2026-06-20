import SwiftUI
import Observation

@MainActor
struct MenuBarPopoverView: View {
    @Environment(ConversionHistory.self) private var history
    @State private var inputText: String = ""
    @State private var currentResult: ConversionResult?
    @State private var showSettings = false
    @AppStorage("outputMilliseconds") private var outputMilliseconds = false

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                SettingsView {
                    showSettings = false
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                mainContent
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .background(.regularMaterial)
        .animation(.easeInOut(duration: 0.2), value: showSettings)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Input area
            ConversionInputView(
                text: $inputText,
                classification: currentClassification
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Result display
            if let result = currentResult {
                ResultDisplayView(result: result)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .padding(.horizontal, 16)

            // History list
            HistoryListView()
                .frame(minHeight: 80, maxHeight: 280)

            Divider()
                .padding(.horizontal, 16)

            // Bottom toolbar
            bottomToolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .onChange(of: inputText) { _, newValue in
            performConversion(newValue)
        }
    }

    // MARK: - Private

    private var currentClassification: InputClassification {
        guard !inputText.isEmpty else { return .unrecognized }
        return ConversionEngine.classify(inputText)
    }

    private var bottomToolbar: some View {
        HStack {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("设置")

            Spacer()

            Text("iTime")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("退出")
        }
    }

    private func performConversion(_ text: String) {
        let precision: OutputPrecision = outputMilliseconds ? .milliseconds : .seconds
        if let result = ConversionEngine.convert(text, outputPrecision: precision) {
            withAnimation(.easeIn(duration: 0.15)) {
                currentResult = result
            }
            history.add(result)
        } else if text.isEmpty {
            withAnimation {
                currentResult = nil
            }
        }
    }
}

import AppKit

/// Provides macOS Services Menu integration.
/// Appears in right-click → Services → "iTime: 转换时间" in any app.
///
/// IMPORTANT: This class must NOT be @MainActor because the ObjC runtime
/// calls convertText from a background thread via NSPortName messaging.
final class ServicesMenuProvider: NSObject {

    /// The service handler method. Must match the ObjC selector exactly:
    /// - (void)convertText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
    @objc(convertText:userData:error:)
    func convertText(
        _ pasteboard: NSPasteboard,
        userData: String,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            DispatchQueue.main.async {
                ToastService.shared.showMessage("未识别到有效时间")
            }
            return
        }

        // Determine output precision
        let useMilliseconds = UserDefaults.standard.bool(forKey: "outputMilliseconds")
        let precision: OutputPrecision = useMilliseconds ? .milliseconds : .seconds

        // Find all time-related content in the text
        let results = extractAndConvert(text, precision: precision)

        DispatchQueue.main.async {
            if results.isEmpty {
                ToastService.shared.showMessage("未识别到有效时间")
                return
            }

            if results.count == 1 {
                let result = results[0]
                ClipboardService.shared.writeText(result.output)
                ToastService.shared.show(input: result.input, output: result.output)
                ConversionHistory.shared.add(result)
            } else {
                let outputs = results.map { "\($0.input) → \($0.output)" }.joined(separator: "\n")
                ClipboardService.shared.writeText(results.map(\.output).joined(separator: "\n"))
                ToastService.shared.show(input: "\(results.count)个结果", output: outputs)
                for result in results {
                    ConversionHistory.shared.add(result)
                }
            }
        }
    }

    // MARK: - Private

    private func extractAndConvert(_ text: String, precision: OutputPrecision) -> [ConversionResult] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // First, try converting the entire text as one value
        // (ConversionEngine now handles time extraction internally)
        if let result = ConversionEngine.convert(trimmed, outputPrecision: precision) {
            return [result]
        }

        // Try to extract individual tokens and convert each
        let tokens = trimmed.split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
        var results: [ConversionResult] = []
        for token in tokens {
            let str = String(token)
            if let result = ConversionEngine.convert(str, outputPrecision: precision) {
                results.append(result)
            }
        }

        return results
    }
}

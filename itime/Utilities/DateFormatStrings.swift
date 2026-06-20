import Foundation

/// Centralized date format string constants.
enum DateFormatStrings {
    // Display output
    static let displayDate = "yyyy-MM-dd HH:mm:ss"
    static let displayDateNoSeconds = "yyyy-MM-dd HH:mm"

    // Chinese
    static let chineseFull = "yyyy年MM月dd日 HH:mm:ss"
    static let chineseMedium = "yyyy年MM月dd日"
    static let chineseShort = "yyyy年M月d日"
    static let chineseShortWithTime = "yyyy年M月d日 HH:mm:ss"

    // Slash-separated (double-digit)
    static let slashFull = "yyyy/MM/dd HH:mm:ss"
    static let slashDate = "yyyy/MM/dd"
    // Slash-separated (single-digit)
    static let slashFullShort = "yyyy/M/d H:mm:ss"
    static let slashDateShort = "yyyy/M/d"

    // Dot-separated (double-digit)
    static let dotFull = "yyyy.MM.dd HH:mm:ss"
    static let dotDate = "yyyy.MM.dd"
    // Dot-separated (single-digit)
    static let dotFullShort = "yyyy.M.d H:mm:ss"
    static let dotDateShort = "yyyy.M.d"

    // Compact
    static let compactFull = "yyyyMMddHHmmss"
    static let compactDate = "yyyyMMdd"

    // English natural
    static let englishFull = "MMM d, yyyy h:mm:ss a"
    static let englishShort = "MMM d, yyyy"
    static let englishRFC = "EEE, dd MMM yyyy HH:mm:ss"

    // Dash date with time (non-ISO)
    static let dashFull = "yyyy-MM-dd HH:mm:ss"
    static let dashFullShort = "yyyy-M-d H:mm:ss"

    // Time only
    static let timeFull = "HH:mm:ss"
    static let timeShort = "HH:mm"
}

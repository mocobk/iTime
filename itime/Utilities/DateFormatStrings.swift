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

    // Slash-separated
    static let slashFull = "yyyy/MM/dd HH:mm:ss"
    static let slashDate = "yyyy/MM/dd"

    // Dot-separated
    static let dotFull = "yyyy.MM.dd HH:mm:ss"
    static let dotDate = "yyyy.MM.dd"

    // Compact
    static let compactFull = "yyyyMMddHHmmss"
    static let compactDate = "yyyyMMdd"

    // English natural
    static let englishFull = "MMM d, yyyy h:mm:ss a"
    static let englishShort = "MMM d, yyyy"
    static let englishRFC = "EEE, dd MMM yyyy HH:mm:ss"

    // Time only
    static let timeFull = "HH:mm:ss"
    static let timeShort = "HH:mm"
}

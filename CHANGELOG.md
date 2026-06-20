# Changelog

All notable changes to iTime will be documented in this file.

## [1.0.3] - 2026-06-20

### New Features

- 菜单栏图标右键菜单：显示窗口、设置、退出三个快捷入口
- 设置页面增加「关于」信息：版本号、作者（mocobk）、邮箱（mailmzb@qq.com）
- VERSION 文件作为版本号单一来源，generate_xcodeproj.py 和 build.sh 自动读取

### Improvements

- Toast 消息居中显示于屏幕中央，字体加大一倍（28pt），保留原有 .ultraThinMaterial 背景和前景色
- Toast 窗口圆角外区域完全透明（无阴影），圆角内为毛玻璃材质
- Toast 文本完整展示，不再因宽度限制截断显示（移除 lineLimit/truncationMode/手动截断逻辑，窗口宽度自适应内容长度）
- 点击历史记录仅复制到剪贴板，不再弹出 Toast 消息
- 历史记录去重：相同 input+output+direction 的记录只保留一条，时间更新为最新
- 日期→时间戳转换自动过滤多余字符（如"2025-06-20 09:00:01其余字符"只展示"2025-06-20 09:00:01"）
- 未识别到有效时间时 Toast 只提示"未识别到有效时间"，不展示 input→output 格式
- 右键菜单背景跟随系统外观（亮色/深色自适应），不强制指定

### Architecture Changes

- 移除 SwiftUI MenuBarExtra，改用手动 NSStatusItem 管理（支持左键 popover + 右键菜单）
- 新增 AppState 共享状态类，让 AppDelegate 右键菜单可以控制 popover 内的设置页面切换
- ConversionEngine 转换流程改为「先提取时间子串，再尝试完整输入」的优先级
- DateParser 新增 parseStrict 方法，通过"格式化回验"确保整个字符串被消费，拒绝带尾随字符的输入
- DateParser 全局 isLenient 从 true 改为 false（严格解析模式）
- 新增多种单数字位日期格式支持（斜杠/点/横线的 yyyy/M/d H:mm:ss 等变体），确保 strict 模式下灵活输入仍可解析
- ToastService 使用 NSPanel + NSHostingView 实现浮动 HUD，背景透明、圆角内毛玻璃
- ClipboardService 精简为仅读写功能，移除后台剪贴板监听及相关设置项

### Bug Fixes

- 修复 ISO8601DateFormatter 解析部分字符串（如 iso8601DateFormatter 只解析"2025-06-20"而忽略"09:00:01其余字符"），在 parseStrict 中新增 tryISO8601Strict 格式化回验
- 修复右键菜单"设置"点击后未正确进入设置页面（改用 AppState.shared 控制 popover 内设置视图切换）

### Tests

- 新增 testExtractsDateWithTrailingChars 用例验证"2025-06-20 09:00:01其余字符"转换只提取时间部分
- 新增 testExtractsDateWithTimeSuffix 用例验证"2025-06-20 09:00:01时间"转换去尾
- 新增 testExtractsTimestampFromMixedInput、testExtractsTimestampWithChineseSuffix、testExtractsTimestampWithChinesePrefix 等提取相关用例
- 新增 testPureTimestampNotModified、testPureDateNotModified 确保纯时间输入不被误修改

## [1.0.0] - 2025-06-20

### Initial Release

- macOS 菜单栏时间转换工具：时间戳→日期、日期→时间戳双向转换
- 支持多种日期格式：ISO8601、中文、斜杠、点分隔、横线、英文、紧凑格式
- 支持秒/毫秒/微秒时间戳
- 历史记录列表
- 全局快捷键唤起
- Services Menu 系统服务集成

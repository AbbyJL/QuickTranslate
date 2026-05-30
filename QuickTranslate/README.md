# QuickTranslate

macOS 菜单栏即时翻译工具 —— 连续按两次 ⌘C 自动翻译选中文本。

## 功能

- **双击 ⌘C 触发翻译**：无需切换窗口，选中文本后快速连按两次 Command+C
- **菜单栏 Popover 展示**：翻译结果悬浮显示在菜单栏下方
- **自动语言检测**：自动识别源语言，翻译为中文
- **纯原生实现**：Swift + SwiftUI，无第三方依赖

## 安装

```bash
git clone https://github.com/AbbyJL/QuickTranslate.git
cd QuickTranslate/QuickTranslate
bash build.sh
open build/QuickTranslate.app
```

## 使用

1. 运行后菜单栏出现「译」图标
2. 在任意应用中选中文本
3. 快速连按两次 ⌘C
4. 翻译结果自动弹出
5. 单击菜单栏图标可查看或退出

## 技术栈

- Swift / SwiftUI
- macOS AppKit (NSStatusItem, NSPopover)
- Google Translate API

## 系统要求

macOS 12.0+

## License

MIT

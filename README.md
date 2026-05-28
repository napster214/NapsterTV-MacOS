# NapsterTV macOS

macOS 桌面版本的 NapsterTV 应用，功能与 iOS 版本 1:1 对齐。

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Swift 5.9+

## 构建方式

```bash
swift build
```

## 运行

```bash
swift run
```

或用 Xcode 打开 `Package.swift` 运行。

## macOS 适配特性

- **侧边栏导航**：使用 `NavigationSplitView` 替代 iOS 的 TabBar
- **原生窗口**：默认 1200x800 窗口，支持自由调整大小
- **键盘快捷键**：
  - `空格` - 播放/暂停
  - `←` / `→` - 快退/快进 10 秒
  - `⌘W` - 关闭窗口
  - `Esc` - 关闭弹窗
  - `⌘Return` - 保存表单
- **原生播放器**：使用 `NSViewRepresentable` 封装 `AVPlayerLayer`
- **响应式网格**：使用 5 列网格替代 iOS 的 3 列，更好利用桌面大屏
- **macOS 表单样式**：使用 `.formStyle(.grouped)` 提供原生体验

## 项目结构

```
Sources/NapsterTV/
├── App/              # 应用入口、导航路由
├── Components/       # 可复用 UI 组件
├── Models/           # 数据模型
├── Services/         # 网络、持久化、API 服务
├── Utilities/        # 工具类和扩展
├── ViewModels/       # MVVM ViewModel
└── Views/            # 页面视图
    ├── Browse/       # 电影/剧集浏览
    ├── Detail/       # 详情页
    ├── Favorites/    # 收藏
    ├── History/      # 播放历史
    ├── Home/         # 首页
    ├── Player/       # 播放器
    ├── Search/       # 搜索
    └── Settings/     # 设置
```

## 依赖

- [Kingfisher 8.9.0](https://github.com/onevcat/Kingfisher) - 图片加载和缓存

# VibePilot

[English](README.md) | [简体中文](README.zh-CN.md)

一个面向 `vibe coding` 的 macOS 菜单栏工具：用摄像头识别手势，把动作映射成键盘/鼠标事件，实现免手输入。

当前仓库按开源项目方式组织（参考 [`dorso`](https://github.com/tldev/dorso) 的结构思路）：

- SwiftPM 工程（`Core + App + Tests`）
- 菜单栏 App 入口
- 摄像头权限 + 摄像头采集 + Vision 手部关键点链路
- 手势识别（`OK` / `Fist` / `OpenPalm`）+ 去抖/冷却
- `CGEvent` 键盘/鼠标注入
- `Scripts/` 打包脚本（可生成 `.app`）
- 基础开源文档（`PRIVACY.md` / `CHANGELOG.md` / `LICENSE`）

## 快速开始

### 依赖

- macOS 13+
- Xcode Command Line Tools（`xcode-select --install`）

### 本地运行

```bash
swift build
swift test
Scripts/dev.sh
```

### 打包 `.app`

```bash
Scripts/package_app.sh
open build/VibePilot.app
```

说明：当前默认是菜单栏应用，启动后不会显示 Dock 图标。

## 权限说明

当前 MVP 路径使用的权限：

- `Camera`（手势识别必须）
- `Accessibility`（键盘/鼠标事件注入必须）

当前版本不需要录屏权限（Screen Recording）。

## 项目结构

```text
vibePilot/
├── Package.swift
├── README.md
├── README.zh-CN.md
├── docs/
│   └── PRD.md
├── Scripts/
│   ├── dev.sh
│   ├── package_app.sh
│   ├── release.sh
│   └── version.env
├── Sources/
│   ├── App/
│   │   ├── VibePilotMain.swift
│   │   └── AppDelegate.swift
│   └── VibePilotCore/
│       ├── Shared/
│       ├── Camera/
│       ├── Vision/
│       ├── Gesture/
│       ├── Binding/
│       ├── Input/
│       ├── Permissions/
│       ├── Persistence/
│       ├── MenuBar/
│       └── UI/
└── Tests/
    └── VibePilotCoreTests/
```

## 当前状态

- 已打通 MVP 主链路：摄像头权限 -> 摄像头帧 -> Vision 手部关键点 -> 手势分类 -> 可选输入注入
- 菜单栏可看到权限状态与运行状态
- 设置页仍是轻量骨架（以展示为主，还不是完整编辑器）

## 文档

- PRD：`docs/PRD.md`
- 隐私说明：`PRIVACY.md`

## License

MIT（见 `LICENSE`）

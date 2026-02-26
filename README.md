# VibePilot

一个面向 `vibe coding` 的 macOS 菜单栏工具：用摄像头识别手势，把动作映射成键盘/鼠标事件，实现免手输入。

当前仓库已按开源项目方式搭好基础骨架（参考 `dorso` 的组织思路）：

- `SwiftPM` 工程（`Core + App + Tests`）
- 菜单栏 App 入口（最小可运行骨架）
- 配置持久化 / 权限管理 / 输入注入的占位实现
- `Scripts/` 打包脚本（可生成 `.app`）
- 开源文档基础文件（`PRIVACY.md` / `CHANGELOG.md` / `LICENSE`）

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

## 项目结构

```text
vibePilot/
├── Package.swift
├── Readme.md                 # 当前 README（大小写保留）
├── docs/
│   └── PRD.md                # 原始产品文档（从旧 Readme 迁移保留）
├── Scripts/
│   ├── dev.sh
│   ├── package_app.sh
│   ├── release.sh
│   └── version.env
├── Sources/
│   ├── App/                  # 可执行入口（薄）
│   │   ├── VibePilotMain.swift
│   │   └── AppDelegate.swift
│   └── VibePilotCore/        # 核心逻辑（可测试）
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

- 已完成：项目骨架、模块分层、默认映射配置、基础测试样例
- 未完成：Vision 手势识别规则、摄像头采集链路、真实设置页交互、完整权限引导

## 下一步建议（MVP 顺序）

1. 打通 `CameraManager -> VisionEngine -> GestureRecognizer`
2. 实现 `OK / Fist / OpenPalm` 规则识别
3. 接入 `InputInjector` 注入 `Enter / Esc`
4. 菜单栏开始/暂停联动识别状态
5. 设置页支持绑定编辑与参数持久化

## 文档

- 产品需求文档（PRD）：`docs/PRD.md`
- 隐私说明：`PRIVACY.md`

## License

MIT（见 `LICENSE`）

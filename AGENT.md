# VibePilot Agent Guide

本文件用于约束在本仓库内工作的 AI / 自动化代理行为，目标是让改动更稳、更容易维护。

## 语言与沟通

- 对用户回复默认使用中文
- 代码注释使用英文
- 搜索资料/检索关键词优先使用英文

## 项目目标（当前阶段）

- 这是一个 macOS 菜单栏应用（SwiftPM）
- 核心路径：`Camera permission -> camera frames -> Vision hand pose -> gesture classification -> input injection`
- 当前 MVP 权限只涉及：
  - `Camera`
  - `Accessibility`
- 当前版本不应引入 `Screen Recording` 权限需求（除非用户明确要求）

## 项目结构（约定）

- `Sources/App/`：App 入口、菜单栏、窗口协调（保持薄）
- `Sources/VibePilotCore/`：核心业务逻辑（可测试）
- `Tests/VibePilotCoreTests/`：单元测试（优先测规则/状态机/去抖冷却）
- `Scripts/`：开发与打包脚本
- `docs/PRD.md`：产品需求文档（功能变更时同步更新）

## 开发原则

- 最小化修改，避免无关重构
- 不要过度设计，优先简单实用
- 保持模块边界清晰：
  - 识别链路逻辑放 `VibePilotCore`
  - UI/菜单栏协调放 `App`
- 优先复用现有数据结构与管理器（如 `BindingManager`、`PermissionManager`）
- 避免引入大型第三方依赖；优先使用 Apple 原生框架

## 权限与隐私约束（重要）

- 不要为当前 MVP 增加录屏权限申请逻辑
- 摄像头仅用于本地实时识别
- 默认不保存视频帧/截图到磁盘
- 如果增加日志，避免记录敏感图像数据

## 验证与运行

在提交代码前，优先执行：

```bash
swift test
Scripts/package_app.sh
```

本地调试常用：

```bash
Scripts/dev.sh
```

菜单栏应用默认无 Dock 图标，这是预期行为。

## 文档约定

- `README.md` 为英文（默认展示）
- `README.zh-CN.md` 为中文版本
- 修改用户可见行为（权限、安装、运行方式）时，同步更新 README
- 任何用户可见功能改动、权限变更、交互变化、发布脚本/工作流变更，提交前必须更新 `CHANGELOG.md`（至少写到 `Unreleased`）
- 如果本次改动没有更新 `CHANGELOG.md`，需要在说明中明确给出理由（例如纯注释/纯重构/无行为变化）

## 版本与发布约定

- 版本号格式：`0.YYYYMMDD.N`（例如 `0.20260226.1`）
- Git tag 格式：`v0.YYYYMMDD.N`
- `N` 为当天第几个发布包，从 `1` 开始递增
- 自动发布工作流会基于当天已有 tag 自动计算下一个版本号

## 代码风格（简版）

- 保持函数职责单一，控制圈复杂度
- 优先小而清晰的方法，避免把状态机逻辑塞进 UI 层
- SwiftUI 视图以“展示与交互”为主，业务逻辑下沉到 Core/Manager

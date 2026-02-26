# CLAUDE.md

请遵循本仓库的代理约定文件：`AGENT.md`。

核心要求（摘要）：

- 默认中文回复，代码注释用英文
- 当前 MVP 仅使用 `Camera` 与 `Accessibility` 权限
- 不要引入录屏权限（Screen Recording），除非用户明确要求
- 优先保持 `Sources/App`（协调层）与 `Sources/VibePilotCore`（核心逻辑）的边界清晰
- 提交前优先执行 `swift test` 和 `Scripts/package_app.sh`


VibePilot 产品文档（PRD）

1. 产品概述

产品名称：VibePilot
一句话：用摄像头识别头部/手势/身体姿势，把动作映射成键盘与鼠标操作，实现“免手输入”的 vibe coding 交互。
平台：macOS（原生 Swift；建议 SwiftUI）
核心能力：
	1.	摄像头实时识别姿势/手势
	2.	动作 → 可配置的键盘/鼠标事件映射
	3.	后台运行、低延迟、低误触发、可暂停

⸻

2. 目标用户与使用场景

目标用户
	•	开发者（vibe coding / code review / AI 辅助编程时用“接受/拒绝/下一条”）
	•	需要减少手部操作的人群（效率与轻量辅助）

典型场景
	•	IDE / ChatGPT / Copilot：点头=Accept（Enter），握拳=Reject（Esc），手势左右滑=上一条/下一条
	•	演示 / 录屏：手势触发翻页、开始/停止录制
	•	辅助控制：远距离控制 Mac（键鼠注入）

⸻

3. 产品目标与非目标

目标（MVP）
	•	实现稳定的手势识别（至少 3 个手势）
	•	每个动作可绑定键盘事件（Enter/Esc/快捷键）
	•	有去抖、冷却时间、防误触发机制
	•	权限引导：摄像头 + Accessibility
	•	状态栏运行（menubar app）：快速开关识别

非目标（MVP 不做）
	•	云端推理 / 账号系统
	•	屏幕内容识别（不需要 Screen Recording）
	•	复杂 3D 头部姿态估计（先做规则/轨迹）
	•	训练自定义模型（后续版本再做）

⸻

4. 功能需求（FRD）

4.1 摄像头与预览
	•	支持选择摄像头（默认系统默认摄像头）
	•	支持预览画面开关（MVP 可默认关闭，以减少 UI 干扰）
	•	帧率：默认 15 FPS（可配置 10~30）

验收：App 能稳定获取帧并输出 Vision 识别结果。

⸻

4.2 姿势/手势识别

MVP（优先手势）
使用 Vision：
	•	VNDetectHumanHandPoseRequest

支持手势（至少 3 个）：
	1.	OK（拇指与食指形成圈） → Action: Accept
	2.	Fist（握拳） → Action: Reject
	3.	OpenPalm（张开手掌） → Action: Pause/Resume（切换识别）

识别规则：
	•	每帧取关键点（21 点），计算关键点距离与角度
	•	置信度阈值：关键点 confidence >= 0.3（可配置）
	•	连续 N 帧满足才触发：默认 N=5
	•	触发后冷却：默认 800ms（可配置）

验收：正常光照下，1 米内识别成功率高；不会连续狂触发。

后续（非 MVP，但预留接口）
	•	头部：VNDetectFaceLandmarksRequest（点头/摇头）
	•	身体：VNDetectHumanBodyPoseRequest

⸻

4.3 动作 → 键鼠映射（核心）

动作（GestureEvent）
	•	ok
	•	fist
	•	openPalm
	•	（预留）nod, shake, thumbsUp, twoFingerSwipeLeft 等

操作（Binding）
	•	Keyboard:
	•	单键：Enter、Esc、Space、Tab、方向键等
	•	组合键：Cmd/Ctrl/Opt/Shift + Key（例如 Cmd+Enter）
	•	Mouse（MVP 可先做点击，移动/滚轮后做）：
	•	LeftClick / RightClick
	•	ScrollUp / ScrollDown（可选）
	•	MoveCursor（可选）

实现要求：
	•	使用 CGEventCreateKeyboardEvent / CGEventCreateMouseEvent / CGEventPost
	•	发送组合键需要设置 flags（command/control/option/shift）
	•	每个动作只能绑定一个操作（MVP），后续可扩展为多个操作序列（macro）

验收：绑定 Enter/Esc 能在任意 App（IDE/浏览器）生效。

⸻

4.4 运行模式与 UI

Menubar（状态栏）模式（推荐 MVP）
	•	菜单项：
	•	Toggle：Start/Stop Recognition
	•	Open Settings…
	•	Show Debug Overlay（可选）
	•	Quit

设置页（SwiftUI）
	•	手势列表 + 当前绑定展示
	•	点击某手势 → 选择绑定：
	•	常用键预设下拉（Enter/Esc/Space/Tab/Arrows）
	•	修饰键勾选（Cmd/Ctrl/Opt/Shift）
	•	Key 输入（字符键或 keycode 选择）
	•	灵敏度设置：
	•	置信度阈值
	•	连续帧数 N
	•	冷却时间 cooldown
	•	摄像头选择（可选）
	•	“暂停识别时提示”开关（通知 or 状态栏图标变化）

验收：用户能在 UI 中完成绑定并立即生效。

⸻

4.5 权限与引导（必须）

需要权限：
	1.	Camera：访问摄像头
	2.	Accessibility：控制键鼠（注入事件）

要求：
	•	启动时检测权限状态
	•	未授权时展示引导页/弹窗：
	•	告知原因
	•	提供按钮跳转系统设置对应页面（或打开隐私面板入口）
	•	权限 OK 才允许开始识别（或允许开始但提示不会生效）

验收：首次安装无权限也不崩溃；引导清晰。

⸻

4.6 存储与配置
	•	本地存储映射与设置（UserDefaults 或 JSON）
	•	数据结构版本化（schemaVersion），便于后续升级

验收：重启后设置仍在。

⸻

5. 非功能需求（NFR）

5.1 性能
	•	推理延迟：目标 < 100ms（15fps 下）
	•	CPU 占用：MVP 目标常态 < 20%（视机型）
	•	处理策略：只处理最新帧（丢帧，不累积延迟）

5.2 稳定性与防误触发
	•	置信度过滤
	•	连续帧确认（debounce）
	•	触发冷却（cooldown）
	•	暂停模式（OpenPalm 切换）
	•	Debug overlay 可显示当前识别的手势与置信度（便于调参）

5.3 隐私
	•	默认不保存视频帧、不上传网络
	•	仅在本地实时处理
	•	Debug 模式可选“保存日志”，但不保存图像（MVP 建议不做保存）

⸻

6. 技术方案（给 AI 写代码用）

6.1 架构模块
	1.	CameraManager

	•	AVCaptureSession
	•	AVCaptureVideoDataOutput
	•	输出 CVPixelBuffer / CMSampleBuffer

	2.	VisionEngine

	•	接收 pixelBuffer
	•	根据模式运行 VNRequests（MVP：HandPose）
	•	输出标准化关键点数据结构（含置信度、时间戳）

	3.	GestureRecognizer

	•	输入关键点序列
	•	输出 GestureEvent（ok/fist/openPalm）
	•	内部实现：规则 + 滑动窗口 + debounce/cooldown

	4.	BindingManager

	•	管理 GestureEvent -> Binding
	•	提供读写持久化
	•	提供默认映射

	5.	InputInjector

	•	发送键盘/鼠标 CGEvent
	•	提供 inject(binding:)

	6.	AppState

	•	isRunning、isPaused
	•	权限状态
	•	当前识别结果（debug）

6.2 关键数据结构（示例）
	•	enum GestureEvent { case ok, fist, openPalm /* future */ }
	•	struct KeyBinding {
	•	let keyCode: CGKeyCode
	•	let modifiers: CGEventFlags
	•	}
	•	enum BindingAction { case keyboard(KeyBinding), mouse(MouseBinding) }
	•	struct MouseBinding {
	•	type: leftClick/rightClick/scrollUp/scrollDown/move(dx,dy)
	•	}
	•	struct AppSettings {
	•	confidenceThreshold: Float
	•	framesRequired: Int
	•	cooldownMs: Int
	•	fps: Int
	•	}

6.3 识别算法（手势规则建议）
	•	OK：distance(thumbTip, indexTip) 小于阈值 && 其他指尖与掌心距离较大（表示其他手指伸展/半伸展）
	•	Fist：所有指尖到掌心距离都小（收拢）
	•	OpenPalm：指尖到掌心距离大，且五指张开（指尖彼此距离也大）

阈值都要做归一化：
	•	用手掌尺度归一化（比如 distance(wrist, middleMCP) 当作 scale）

6.4 权限检测
	•	Camera：检查/请求 AVCaptureDevice.authorizationStatus(for: .video)
	•	Accessibility：AXIsProcessTrustedWithOptions（提示用户去设置打开）

⸻

7. MVP 默认映射（建议）
	•	OK → Enter（Accept）
	•	Fist → Esc（Reject）
	•	OpenPalm → Pause/Resume（不注入键，只切换内部状态）

⸻

8. 测试验收清单
	•	无权限启动不崩溃，提示清晰
	•	授权 Camera + Accessibility 后可正常注入 Enter/Esc
	•	识别稳定：OK/Fist/OpenPalm 在正常光照下成功率高
	•	不会连发：同一动作触发后 cooldown 生效
	•	设置修改后立即生效，重启仍保存
	•	Menubar 开关可用，暂停状态有明显提示

⸻

9. 迭代路线（可选）
	•	v0.2：增加鼠标点击/滚轮；增加 debug overlay（骨架/关键点）
	•	v0.3：点头/摇头（FaceLandmarks + 轨迹检测）
	•	v0.4：自定义手势训练（CoreML）或录制动作
	•	v1.0：宏（动作序列）、多 Profile（不同软件不同映射）、开机自启
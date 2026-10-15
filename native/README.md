# Hades Tools v0.2.6

本版面向 Windows x64 下的 Hades，使用 C++17、Qt 6.8.3 和 material-components-qml。

## 运行

1. 保留发布包的完整目录结构，双击 `HadesTools.exe`。
2. 启动 Hades 的 x64 版本，加载存档并回到游戏画面。
3. 点击“连接游戏”，连接成功后即可操作。暂停菜单会停止游戏脚本线程，操作前请关闭菜单。
4. 结束使用时关闭工具窗口，连接服务随之退出并恢复游戏原有的后台更新设置。

发布包内含 Qt、MinGW 运行库和 `bridge/HadesToolsBridge.exe`，使用时无需安装 Python、Qt、CE 或 IDA。
修改资源、祝福和角色属性后，游戏正常保存时可能将变化写入存档。退出工具会恢复后台更新设置，已修改的数值由使用者决定是否还原。

如需单文件启动，使用 `dist/HadesTools-v0.2.6-single.exe`。它会在 `%TEMP%` 自动展开完整运行目录并启动主程序，EXE 所在目录无需放置 Qt DLL、桥接文件或其他运行库；首次启动需要系统自带的 Windows PowerShell 用于解压内置 ZIP。

## 功能

- 概览：人物信息与生命比例条；图标卡片显示速度、伤害倍率、暴击加成、神力值、本局金币、重掷、效果数量和工具无敌状态。效果列表显示当前语言的名称、类别、稀有度和已有的等级数据。
- 功能：核心功能优先展示无敌、无限投弹等持续战斗开关，并提供完全治疗和刷新状态快捷操作。
- Ragebot：适配狮鹫坚炮与索心弓，使用游戏原生批量候选查询，在同一帧跳过死亡、无敌、超距、遮挡目标并切换下一个有效目标；自动瞄准逐帧转向并同步手动射击目标，自动开火服从游戏原生攻击就绪、枪械弹药/换弹和弓蓄力状态。兼容坚炮升级后的 `MaxAmmo=-1` 无限弹药语义以及 `NumProjectiles`/`ProjectileInterval` 三连发，不会因弹药计数变为负值而停止。每次自动射击都会重新验证目标并计算玩家到目标的原生世界角度，将弧度值直接交给发射请求；Ragebot 启用期间收束散射和投射物角度偏移，提升多投射物命中率，关闭或切换武器时恢复升级后的原始属性。静默射击不改变角色或准星朝向。
- 自身状态：集中编辑当前/最大生命、冲刺次数、神力值、速度、伤害倍率、暴击加成、本局金币和重掷次数；读取并编辑当前祝福、稀有度、等级和武器强化字段。祝福等级使用游戏原生的同名祝福实例数，修改后立即读回状态。
- 布局：概览和功能卡片按内容计算高度，统一使用组件内边距；窄窗口自动减少列数，侧栏菜单支持滚动；滚动条提供 16 像素交互区域、常显滑块、轨道跳转和连续拖动。
- 窗口：无边框标题栏内置最小化、最大化/还原和关闭按钮；标题栏支持拖动和双击切换大小，窗口边缘和四角支持缩放。
- 搜索：资源、道具、祝福、奖励和武器页面支持中文名称、英文名称及原始键搜索；点击搜索或按回车执行，清空输入恢复完整目录。
- 译名：571 项目录中已有 446 项直接使用游戏官方简体中文文本，其余内部运行时键保留可编辑译名；中英文随界面语言切换，列表同时保留原始键便于核对。
- 资源：读取和设置游戏中的 7 类资源。
- 道具：搜索 56 个目录项，生成物品并读回对象 ID；按 ID 清理生成对象。
- 祝福：搜索 487 个目录项，添加、移除及选择稀有度。
- 奖励：15 个目录项，生成神祇奖励并清理对象。
- 武器：切换六把英雄武器。
- 日志：按完整时间记录任务、参数、目标和执行结果，最多保留 300 条。
- 日志保留本次运行的成功、失败和取消记录，最新任务在前；支持手动清空。
- 界面：中文采用系统宋体加粗，英文采用 Segoe UI。左下角使用语言 SVG 图标切换并保存选择，悬停显示目标语言，切换时淡出淡入。
- 导航：功能分区采用淡出、滑入过渡，选中背景平滑移动；页面输入与筛选状态保留。
- 关于：左下角感叹号 SVG 打开关于页预留区域，可继续扩展内容。
- 状态：连接后每秒读取生命、属性、本局数据和资源；前台任务执行期间自动暂停轮询。
- 后台刷新不会反复生成成功日志或禁用操作；编辑中的输入保持原样。读取失败时停止轮询并显示错误，关闭暂停菜单后点击“刷新状态”恢复。

目录直接读取当前游戏的 Lua 数据表。上述数量来自已验证的游戏构建，目录内部分内部条目需要对应房间或游戏状态；执行错误会显示在底栏。

## 修改物品中文名称

打开程序目录中的 `translations/catalog.zh-CN.json`，修改对应条目的 `zh` 字段，以 UTF-8 保存并重新启动程序。保留分类名称和条目原始键，游戏操作始终使用原始键。`en` 是英文显示名，也参与搜索。

目录包含资源 7 项、道具 56 项、祝福 487 项、神祇奖励 15 项和英雄武器 6 项。当前已有 446 个名称直接来自本机 Hades 的官方 `zh-CN` 文本表，条目的 `source` 字段记录为 `game-official-zh-CN`；游戏文本表未定义的 125 个内部运行时键保留原有译名，并记录在 `analysis/hades_trainer/catalogs/catalog.zh-CN.import-report.json`。

从另一份 Hades 安装导入官方中文名称：

```powershell
python tools\import_game_text_catalog.py `
  --text-root 'D:\Steam\steamapps\common\Hades\Content\Game\Text\zh-CN' `
  --catalog translations\catalog.zh-CN.json `
  --output translations\catalog.zh-CN.json `
  --report ..\analysis\hades_trainer\catalogs\catalog.zh-CN.import-report.json
```

工具按官方文本表的 `Id` 键匹配，不会把剧情对话或内部占位键误写入物品名称；资源键会显式映射到 `GemDrop`、`GiftDrop` 等官方文本键。

重新生成需要额外安装 `requirements-translation.txt` 中的开发依赖和 Argos 英译中模型 `translate-en_zh-1_9`，再执行：

```powershell
python tools\translate_catalog.py `
  --catalog verification\v023-catalog.json `
  --english 'D:\Steam\steamapps\common\Hades\Content\Game\Text\en\HelpText.en.sjson' `
  --output translations\catalog.zh-CN.json
```

修改名称无需重新编译。缺失或格式错误的译名文件会在启动时明确报错。官方文本导入工具依赖开发环境中的 `sjson`，不随运行包分发。

## 适配范围

已实测 Steam Hades x64，build ID `10929685`，`EngineWin64s.dll` SHA256：

```text
4165a69c9ed8f48d9c839609011da55c12bbc877eb9b0550c4b099bd0524befd
```

首版使用该引擎构建的函数 RVA，并检查入口机器码。其他引擎构建需要重新采集适配文件；机器码不匹配会明确报错。
武器、奖励和全部祝福目录已经接入；当前自动化实测覆盖连接、属性、资源、道具生成/清理及退出恢复，完整目录尚未逐项执行验证。

## 工程结构

- `src/app`：C++ 应用控制器、生命周期和 QML 启动。
- `src/backend`：Qt Network 串行命令队列、Qt 目录过滤模型。
- `src/qml`：直接复用 `md3.Core` 的八个页面和关于预留页；字体集中在 `UiStyle.qml` 与应用默认字体中管理。
- `third_party/material-components-qml`：固定上游提交 `90dc5217f73cce6ea1ff936605c63e1466db6730`。
- `../analysis/hades_trainer`：游戏适配与脚本桥接源代码。
- `HadesToolsBridge.spec`：将现有 Python/Frida 桥接封装为附带的 EXE。
- `verification`：实际游戏操作读回、截图和进程检查记录。

UI、控制器和模型为 C++/QML；游戏桥接保留 Python/Frida 实现，已独立打包。命令在游戏脚本线程执行，UI 从返回结果更新状态。
本机 HTTP 通信固定直连 `127.0.0.1:27864`，排除系统代理对服务探测的影响。

## 安装开发依赖与构建

先安装 Python 3.12 和 Git。在 PowerShell 中从本目录执行：

```powershell
.\install-environment.ps1 -Python python
.\build.ps1 -Python python
.\package.ps1 -Python python
.\package-source.ps1
```

默认 Qt/MinGW 位置为 `D:\Dev\Qt`，可通过脚本参数指定。Python 命令应从本目录执行，项目根目录中的旧 Python 打包文件会污染模块导入。
`build.ps1` 构建原生程序及桥接 EXE，`package.ps1` 部署运行依赖并生成 ZIP、版本清单和 SHA256 文件。打包前关闭发布程序。
`package-single.ps1` 读取同版本 ZIP，将其附加到原生启动器并生成单文件 EXE 及 SHA256 文件；先执行 `package.ps1`，再执行该脚本。

## 第三方来源

依赖版本和上游地址见 `THIRD_PARTY_NOTICES.md`，发布包附有 `licenses`。新增工程代码使用 MIT；第三方代码与运行库遵循各自的许可和声明。

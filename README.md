# 桌面运维助手 Desktop Ops Assistant

![Tauri](https://img.shields.io/badge/Tauri-2-FFC131?logo=tauri)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)
![Rust](https://img.shields.io/badge/Rust-2021-000000?logo=rust)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Windows%207--11-blue)

桌面运维助手是一款面向 Windows 系统管理员和 IT 运维人员的桌面工具平台，集成 **Microsoft Sysinternals Suite** 的 50+ 经典工具以及 14 个实用 Windows 批处理脚本，提供系统信息看板、分类工具启动器、执行审计与安全策略管理等一站式功能。

---

## 📦 功能概览

| 功能模块 | 说明 |
|----------|------|
| **基本信息看板** | 全面采集 Windows 硬件、系统、磁盘/网络信息，实时刷新 |
| **综合功能（工具启动器）** | 分类浏览并一键启动 Sysinternals 工具和 Windows 批处理脚本 |
| **工具用法速查** | 内置工具语法、命令行参数、使用示例，支持一键复制 |
| **执行历史审计** | 记录工具启动历史（30 条），含耗时、PID、退出码、成功/失败状态 |
| **安全策略管理** | 按风险等级（危险/管理员/敏感/安全）批量启用/禁用工具 |
| **签名验证** | 计算工具文件的 SHA-256 哈希值 |
| **UI 主题切换** | 经典 Windows / Windows 7 Aero / 极简终端 三种配色方案 |

---

## 🖥️ 系统要求

- **操作系统**: Windows 7 SP1 ～ Windows 11（简体中文系统推荐）
- **依赖**: [Microsoft WebView2](https://developer.microsoft.com/microsoft-edge/webview2/)（Windows 10/11 自带，Windows 7 需手动安装）
- **硬盘空间**: ≥ 500 MB（含 Sysinternals 工具集）
- **管理员权限**: 部分工具（如注册表工具、系统设置修改）需要管理员权限运行

---

## 🔧 快速开始

### 1️⃣ 下载与运行

从 [Releases](../../releases) 页面下载最新版本安装包或便携版。运行后程序会自动识别 `SysinternalsSuite/` 目录中的工具。

### 2️⃣ 手动编译

```bash
# 克隆仓库（含子模块）
git clone <repo-url>
cd DesktopOpsAssistant

# 安装前端依赖
npm install

# 构建前端
npm run build

# 构建 Tauri 桌面应用
cd src-tauri
cargo build --release
```

编译产物位于 `src-tauri/target/release/desktop-ops-assistant.exe`。

---

## 📖 使用指南

### 基本信息标签页

打开应用即自动加载系统信息，包含三张信息卡：

| 信息卡 | 采集数据 |
|--------|----------|
| **硬件信息** | BIOS 版本、主板型号、CPU、内存容量、硬盘型号、显卡、声卡、网卡、光驱、显示器、键盘、鼠标、打印机、摄像头 |
| **系统信息** | 操作系统名称/版本、电脑类型、系统目录、主机名、用户名、工作组、分辨率、进程数、安装日期、上次关机时间、开机时间、运行时长 |
| **磁盘/网络** | 各盘符使用情况（总量/已用/可用）、虚拟内存、本机 IP、网关 IP、网卡详情 |

底部状态栏实时显示：本机 IP、网关 IP、当前时间、运行时长、平台信息。

> 💡 **提示**：点击右上角刷新按钮可重新采集所有硬件信息。

### 综合功能标签页（工具启动器）

左侧分类栏展示所有工具分类及数量，点击分类过滤右侧工具卡片。

**工具风险等级标识：**

| 标签 | 含义 | 左侧色条 |
|------|------|----------|
| `管理员` | 需要管理员权限运行 | 🟠 橙色 |
| `敏感` | 可能影响系统配置 | 🟣 紫色 |
| `危险` | 可能导致系统不稳定或数据丢失 | 🔴 红色 |
| *无标签* | 普通工具 | 🔵 蓝色 |

**操作方式：**

- **启动工具**：点击工具卡片任意位置 → 选择执行模式启动
- **查看用法**：工具卡片右上角 `?` 按钮 → 打开用法速查抽屉（语法、选项、示例）
- **复制命令**：用法抽屉中悬停显示复制按钮，点击即可复制到剪贴板

**工具分类：**

| 分类 | 包含工具 |
|------|----------|
| 进程/任务管理 | Process Explorer, Process Monitor, PsExec, PsKill, PsList, Handle, ListDLLs, Autoruns, ShellRunAs |
| 远程管理 | PsExec（远程模式）, PsLoggedOn, PsFile, PsShutdown |
| 文件/磁盘工具 | DiskMon, Disk2vhd, SDelete, PendMoves, MoveFile, Streams, Contig, Junction, FindLinks |
| 安全/权限类 | AccessChk, AccessEnum, ShareEnum, PsExec（安全）, LogonSessions, Sysmon |
| 系统信息类 | CoreInfo, WinObj, ZoomIt, LiveKd, PsInfo, DbgPrint, Winver |
| 网络类 | TCPView, PsPing, Whois, PsFile（网络） |
| 注册表类 | RegJump, ShellRunAs（注册表）, PsExec（注册表） |
| Active Directory | ADExplorer, ADInsight, PsGetSid |
| 调试/诊断类 | DebugView, NotMyFault, RAMMap, VMMap, DumpChk, Strings |
| Windows 批处理工具 | 右键菜单设置、桌面设置、任务栏设置、资源管理器设置、Windows 更新设置、UAC 设置、系统设置集中管理、WiFi 密码、电源管理、应用管理、编辑 Hosts、网络管理、设备管理、Hash 计算 |

### 历史记录标签页

显示当前会话内最近 30 次工具执行记录：

- 成功/失败状态
- 执行消息
- 进程 PID 或退出码
- 执行耗时（毫秒）

可在设置页面导出为 CSV 文件（含 BOM，兼容 Excel 直接打开）。

### 设置标签页

| 设置项 | 说明 |
|--------|------|
| **工具目录** | 配置 Sysinternals 工具存放根目录，应用启动时自动扫描 |
| **安全策略** | 按风险等级（危险/管理员/敏感）批量禁用工具，支持导出安全策略配置 |
| **外观主题** | 经典 Windows / Windows 7 Aero / 极简终端 三种方案 |
| **字体设置** | 自定义界面字体系列和字号 |
| **关于** | 应用版本、技术栈、版权信息 |

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────┐
│              前端 UI (React 19)              │
│  TypeScript + Vite 6 + Tailwind-like CSS    │
│  lucide-react 图标库                         │
└──────────────────┬──────────────────────────┘
                   │ @tauri-apps/api (invoke)
┌──────────────────▼──────────────────────────┐
│           Tauri 2 桥接层 (Rust)              │
│  系统调用 / WMI / 注册表 / 进程管理 / 文件操作 │
├─────────────────────────────────────────────┤
│  │  commands/system_info.rs  ← 系统信息采集  │
│  │  commands/tools.rs        ← 工具启动/管理 │
│  │  commands/signatures.rs   ← 签名验证      │
│  │  db/                      ← SQLite 审计库 │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│            Windows 系统资源                    │
│  Sysinternals Suite / PowerShell / WMI      │
│  注册表 / 文件系统 / SQLite                   │
└─────────────────────────────────────────────┘
```

### 技术栈详情

| 层次 | 技术 | 用途 |
|------|------|------|
| **前端框架** | React 19 + TypeScript | UI 组件与状态管理 |
| **构建工具** | Vite 6 | 前端打包与热更新 |
| **桌面框架** | Tauri 2 | 原生窗口、系统 API、WebView2 渲染 |
| **后端语言** | Rust 2021 | Tauri 命令处理与系统调用 |
| **数据库** | SQLite (tauri-plugin-sql) | 执行审计日志持久化 |
| **系统信息** | sysinfo crate + PowerShell CIM/WMI | 硬件与系统数据采集 |
| **注册表访问** | winreg crate | 读取 BIOS/主板/系统版本等注册表键值 |
| **进程管理** | std::process::Command + ShellExecuteExW | 工具启动、批处理管理员提权 |
| **哈希计算** | sha2 crate | SHA-256 签名验证 |
| **Win32 API** | windows-sys (ShellExecuteExW) | 无闪烁管理员权限启动批处理 |

---

## ⚠️ 安全注意事项

1. **管理员权限**：部分工具的启动会触发 UAC 提权提示，此为正常行为。
2. **系统保护**：`危险` 和 `敏感` 级别的工具默认启用但会在启动前显示确认提示。建议非必要不修改安全策略中的禁用设置。
3. **路径安全**：应用会校验所有启动的可执行文件路径，确保仅在 `SysinternalsSuite/` 或 `Windowsbat/` 目录内运行。
4. **参数过滤**：命令行参数经过安全过滤，拒绝管道符 `| & ; > <` 等特殊字符前缀的命令。
5. **Sysinternals 签名**：所有 Sysinternals 可执行文件均来自微软官方签名版本，建议定期从 [Microsoft Sysinternals](https://learn.microsoft.com/sysinternals) 更新。

---

## 📊 Sysinternals 工具分类速查

### 进程/任务管理
| 工具 | 功能 |
|------|------|
| **Process Explorer** | 高级任务管理器，查看进程/句柄/DLL |
| **Process Monitor** | 实时监控文件系统、注册表、进程活动 |
| **Autoruns** | 管理开机自启动项 |
| **Handle** | 查看哪些进程打开了指定文件 |
| **ListDLLs** | 查看进程加载的 DLL |
| **PsExec** | 远程/本地执行命令 |
| **PsKill** | 强制终止进程 |
| **PsList** | 查看进程信息 |
| **ShellRunAs** | 以不同用户身份运行 |

### 文件/磁盘工具
| 工具 | 功能 |
|------|------|
| **DiskMon** | 监控磁盘活动 |
| **Disk2vhd** | 物理磁盘转 VHD 虚拟磁盘 |
| **SDelete** | 安全删除文件/目录 |
| **Streams** | 查看 NTFS 数据流 |
| **Contig** | 文件碎片整理 |
| **Junction** | 管理目录链接 |

### 网络工具
| 工具 | 功能 |
|------|------|
| **TCPView** | 查看 TCP/UDP 连接和端口 |
| **PsPing** | ICMP/TCP Ping 和延迟测试 |
| **Whois** | 域名 Whois 查询 |
| **PsFile** | 查看远程打开的文件 |

### 系统信息
| 工具 | 功能 |
|------|------|
| **CoreInfo** | CPU 核心/缓存拓扑查看 |
| **WinObj** | 对象管理器命名空间查看 |
| **ZoomIt** | 屏幕放大与标注 |
| **PsInfo** | 系统版本/补丁信息 |

更多工具的详细用法和命令行参数，请在应用中点击工具卡片的 `?` 按钮查看。

---

## 🪟 Windows 批处理工具说明

14 个独立批处理脚本位于 `Windowsbat/` 目录，均可双击独立运行，应用内通过"综合功能"→"Windows 批处理工具"分类启动。

| # | 脚本 | 功能 |
|---|------|------|
| 01 | 右键菜单设置 | Windows 10/11 右键菜单样式切换、文件 Hash 校验菜单 |
| 02 | 桌面设置 | 桌面图标、壁纸、聚焦、版本水印管理 |
| 03 | 任务栏设置 | 任务栏净化、小组件、搜索、自动隐藏 |
| 04 | 资源管理器设置 | 扩展名、隐藏文件、复选框、导航栏设置 |
| 05 | Windows 更新设置 | 暂停更新至 2999 年 / 恢复更新 |
| 06 | UAC 设置 | 从不通知 / 恢复默认 / 彻底关闭 UAC |
| 07 | 系统设置集中管理 | 上帝模式控制面板 |
| 08 | WiFi 密码 | 显示所有已连接 WiFi 名称及密码 |
| 09 | 电源管理 | 定时关机/重启、禁用睡眠、休眠管理 |
| 10 | 应用管理 | 卸载预装应用、程序和功能、OneDrive 管理 |
| 11 | 编辑 Hosts | 以管理员权限打开 hosts 文件 |
| 12 | 网络管理 | DNS 缓存、MAC 地址、Ping、路由追踪、防火墙 |
| 13 | 设备管理 | 禁用/启用摄像头、蓝牙 |
| 14 | Hash 计算 | 计算文件 MD2/MD4/MD5/SHA1/SHA256/SHA384/SHA512 |

---

## 🔐 安全策略管理

在"设置"页面的安全策略区域，可以按风险等级批量启用或禁用工具：

- **危险工具**（如 SDelete、PsKill、注册表工具）—— 建议保持启用但谨慎使用
- **管理员工具**（如 Autoruns、Process Monitor 高级功能）—— 需要管理员权限
- **敏感工具**（如 Handle、ListDLLs、Streams）—— 可能暴露系统内部信息

> 安全策略以 JSON 文件保存在 `%APPDATA%\DesktopOpsAssistant\tool_security_policy.json`，可直接编辑或通过应用内导出备份。

---

## 📝 数据存储

| 数据 | 存储位置 | 说明 |
|------|----------|------|
| **执行审计日志** | SQLite: `desktop-ops-assistant.db` | 应用同级目录 |
| **安全策略配置** | JSON: `%APPDATA%\DesktopOpsAssistant\tool_security_policy.json` | 用户配置目录 |
| **工具根目录缓存** | `%APPDATA%\DesktopOpsAssistant\tool_usage.json` | 工具用法数据库缓存 |
| **UI 偏好设置** | `localStorage`（WebView2 本地存储） | 字体、字号、配色方案 |
| **窗口状态** | Tauri 插件自动管理 | 窗口大小、位置、最大化状态 |

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/your-feature`)
3. 提交更改 (`git commit -m 'Add some feature'`)
4. 推送到分支 (`git push origin feature/your-feature`)
5. 发起 Pull Request

### 开发环境要求

- [Node.js](https://nodejs.org/) ≥ 18
- [Rust](https://www.rust-lang.org/) ≥ 1.84
- [Microsoft Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)（含 C++ 工具集）
- [Microsoft WebView2](https://developer.microsoft.com/microsoft-edge/webview2/)

---

## 📄 许可与免责声明

本项目基于 [MIT License](LICENSE) 开源。

```
MIT License
Copyright (c) 
```

**声明：**

- 本应用仅作为 Sysinternals 工具的启动和管理界面，**不包含** Sysinternals 工具本身的二进制文件。请自行从 [Microsoft Sysinternals](https://learn.microsoft.com/sysinternals/downloads/) 下载 Sysinternals Suite。
- Sysinternals 工具的全部权利归 Microsoft Corporation 所有。
- 14 个 Windows 批处理脚本为独立编写的管理工具，涉及系统设置修改，请在了解各项操作含义后再使用。
- 本软件按"原样"提供，不提供任何明示或暗示的保证。作者不对使用本软件造成的任何直接或间接损失承担责任。
- 建议在使用前备份重要系统和数据。

---

## 📝 更新日志

### v1.0.2 (2026-05-28)

**新增**
- 设置页面新增独立的「批处理目录」配置项，支持单独指定 `Windowsbat` 目录路径
- 为「工具目录」和「批处理目录」两个配置项均添加 📁 浏览按钮，点击可打开系统文件夹选择对话框
- 批处理工具的扫描和启动逻辑改为使用独立的 `bat_root` 路径，不再依赖 `tools_root` 向上派生

**技术**
- 新增 `tauri-plugin-dialog` 依赖，提供原生文件夹选择对话框
- Rust 后端新增 `get_bat_root`、`set_bat_root`、`pick_directory` 三个 Tauri 命令
- `default_bat_root` 支持从 EXE 所在目录向上查找 `Windowsbat` 文件夹

---

### v1.0.1 (2025-05-25)

**修复**
- 修复批处理执行时中间 DOS 窗口闪烁问题：改用 `ShellExecuteExW` + `runas` 直接以管理员权限启动 `.bat`，通过 `SEE_MASK_NO_CONSOLE` 标志消除中间控制台窗口
- 修复 SQLite migration 不一致导致的首次启动崩溃：清理旧数据库并重建 schema
- 移除未使用的 Electron 残留配置

**技术**
- 新增 `windows-sys` 依赖用于调用 `ShellExecuteExW` Win32 API
- 优化系统信息采集的多源降级策略

---

## 🙏 致谢

- [Microsoft Sysinternals](https://learn.microsoft.com/sysinternals/) — 经典系统工具集
- [Tauri](https://tauri.app/) — 轻量级桌面框架
- [React](https://react.dev/) — UI 框架
- [lucide-react](https://lucide.dev/) — 开源图标库
- Windows Sysinternals 实战指南（PDF）— 随 SysinternalsSuite 附带的参考文献

---

*桌面运维助手 — 让系统运维更高效*

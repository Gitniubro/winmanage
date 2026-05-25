use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::Read;
use std::path::PathBuf;
use std::process::Command;
use std::sync::{LazyLock, Mutex};
use sha2::{Sha256, Digest};
use std::fs;

#[cfg(windows)]
mod windows_shell {
    use std::ffi::OsStr;
    use std::iter::once;
    use std::os::windows::ffi::OsStrExt;
    use std::ptr;

    #[repr(C)]
    #[allow(non_snake_case)]
    struct SHELLEXECUTEINFOW {
        cbSize: u32,
        fMask: u32,
        hwnd: *mut std::ffi::c_void,
        lpVerb: *const u16,
        lpFile: *const u16,
        lpParameters: *const u16,
        lpDirectory: *const u16,
        nShow: i32,
        hInstApp: *mut std::ffi::c_void,
        lpIDList: *mut std::ffi::c_void,
        lpClass: *const u16,
        hkeyClass: *mut std::ffi::c_void,
        dwHotKey: u32,
        hMonitor: *mut std::ffi::c_void,
        hProcess: *mut std::ffi::c_void,
    }

    #[link(name = "shell32")]
    extern "system" {
        fn ShellExecuteExW(pExecInfo: *mut SHELLEXECUTEINFOW) -> i32;
    }

    const SEE_MASK_NOCLOSEPROCESS: u32 = 0x00000040;
    const SEE_MASK_NO_CONSOLE: u32 = 0x00008000;
    const SW_SHOWNORMAL: i32 = 1;

    pub fn execute_as_admin(file: &str) -> Result<(), String> {
        let file_wide: Vec<u16> = OsStr::new(file).encode_wide().chain(once(0)).collect();
        let verb_wide: Vec<u16> = OsStr::new("runas").encode_wide().chain(once(0)).collect();

        let mut sei = SHELLEXECUTEINFOW {
            cbSize: std::mem::size_of::<SHELLEXECUTEINFOW>() as u32,
            fMask: SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NO_CONSOLE,
            hwnd: ptr::null_mut(),
            lpVerb: verb_wide.as_ptr(),
            lpFile: file_wide.as_ptr(),
            lpParameters: ptr::null(),
            lpDirectory: ptr::null(),
            nShow: SW_SHOWNORMAL,
            hInstApp: ptr::null_mut(),
            lpIDList: ptr::null_mut(),
            lpClass: ptr::null(),
            hkeyClass: ptr::null_mut(),
            dwHotKey: 0,
            hMonitor: ptr::null_mut(),
            hProcess: ptr::null_mut(),
        };

        unsafe {
            let result = ShellExecuteExW(&mut sei);
            if result == 0 {
                return Err(format!("ShellExecuteExW failed (error: {})", std::io::Error::last_os_error()));
            }
        }
        Ok(())
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Tool {
    pub id: String,
    pub name: String,
    pub display_name: String,
    pub category: String,
    pub description: String,
    pub risk_level: String,
    pub ui_type: String,
    pub preferred_exe: String,
    pub requires_admin: bool,
    pub enabled: bool,
    pub exists_on_disk: bool,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LaunchResult {
    pub success: bool,
    pub message: String,
    pub pid: Option<u32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ToolUsage {
    pub syntax: String,
    pub options: Vec<String>,
    pub examples: Vec<String>,
    pub notes: Option<String>,
}

fn default_tools_root() -> String {
    static CACHE: LazyLock<String> = LazyLock::new(|| {
        if let Ok(exe_path) = std::env::current_exe() {
            if let Some(exe_dir) = exe_path.parent() {
                let mut dir = Some(exe_dir);
                for _ in 0..4 {
                    if let Some(d) = dir {
                        let candidate = d.join("SysinternalsSuite");
                        if candidate.is_dir() {
                            return candidate.to_string_lossy().to_string();
                        }
                        dir = d.parent();
                    }
                }
            }
        }
        if let Ok(cwd) = std::env::current_dir() {
            let candidate = cwd.join("SysinternalsSuite");
            if candidate.is_dir() {
                return candidate.to_string_lossy().to_string();
            }
        }
        String::new()
    });
    CACHE.clone()
}

// ---------- Caches ----------

static TOOLS_ROOT_CACHE: LazyLock<Mutex<Option<String>>> = LazyLock::new(|| Mutex::new(None));
static USAGE_DB_CACHE: LazyLock<Mutex<Option<HashMap<String, ToolUsage>>>> = LazyLock::new(|| Mutex::new(None));

fn app_data_dir() -> PathBuf {
    std::env::var("APPDATA")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("."))
        .join("com.sysinternals.desktop-ops-assistant")
}

fn tools_root_file() -> PathBuf {
    app_data_dir().join("tools_root.txt")
}

pub(crate) fn get_tools_root_path() -> String {
    if let Ok(cache) = TOOLS_ROOT_CACHE.lock() {
        if let Some(ref path) = *cache {
            return path.clone();
        }
    }
    let path = fs::read_to_string(tools_root_file())
        .unwrap_or_else(|_| default_tools_root());
    if let Ok(mut cache) = TOOLS_ROOT_CACHE.lock() {
        *cache = Some(path.clone());
    }
    path
}

fn invalidate_caches() {
    if let Ok(mut cache) = TOOLS_ROOT_CACHE.lock() {
        *cache = None;
    }
    if let Ok(mut cache) = USAGE_DB_CACHE.lock() {
        *cache = None;
    }
}

// ---------- Security Policy ----------

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SecurityPolicy {
    pub disabled_tools: Vec<String>,
}

impl Default for SecurityPolicy {
    fn default() -> Self {
        Self {
            disabled_tools: vec![],
        }
    }
}

fn security_policy_file() -> PathBuf {
    app_data_dir().join("security_policy.json")
}

fn load_security_policy() -> SecurityPolicy {
    let path = security_policy_file();
    fs::read_to_string(&path)
        .ok()
        .and_then(|content| serde_json::from_str(&content).ok())
        .unwrap_or_default()
}

fn save_security_policy(policy: &SecurityPolicy) -> Result<(), String> {
    let dir = app_data_dir();
    fs::create_dir_all(&dir).map_err(|e| format!("无法创建目录: {}", e))?;
    let content = serde_json::to_string_pretty(policy).map_err(|e| format!("序列化失败: {}", e))?;
    fs::write(security_policy_file(), &content).map_err(|e| format!("写入失败: {}", e))
}

#[tauri::command]
pub fn set_tool_enabled(tool_id: String, enabled: bool) -> Result<(), String> {
    let mut policy = load_security_policy();
    if enabled {
        policy.disabled_tools.retain(|t| t != &tool_id);
    } else if !policy.disabled_tools.contains(&tool_id) {
        policy.disabled_tools.push(tool_id);
    }
    save_security_policy(&policy)?;
    invalidate_caches();
    Ok(())
}

#[tauri::command]
pub fn get_security_policy() -> Result<SecurityPolicy, String> {
    Ok(load_security_policy())
}

// ---------- Tool catalog ----------

#[tauri::command]
pub fn scan_tools() -> Result<Vec<Tool>, String> {
    let tools_root = get_tools_root_path();
    let root = PathBuf::from(&tools_root);

    let mut tools = vec![
        // ========== 进程/任务管理类 ==========
        Tool { id: "procexp".to_string(), name: "Process Explorer".to_string(), display_name: "进程管理".to_string(), category: "进程/任务管理类".to_string(), description: "增强版任务管理器，查看进程树、加载的 DLL、打开的句柄、数字签名验证".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "procexp64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "procmon".to_string(), name: "Process Monitor".to_string(), display_name: "系统雷达".to_string(), category: "进程/任务管理类".to_string(), description: "实时监视文件系统、注册表、进程和线程活动，支持详细过滤".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "Procmon.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "pslist".to_string(), name: "PsList".to_string(), display_name: "进程列表".to_string(), category: "进程/任务管理类".to_string(), description: "显示进程和线程的详细信息".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "pslist64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "pskill".to_string(), name: "PsKill".to_string(), display_name: "进程终止".to_string(), category: "进程/任务管理类".to_string(), description: "终止本地或远程进程".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "pskill64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "psservice".to_string(), name: "PsService".to_string(), display_name: "服务管理".to_string(), category: "进程/任务管理类".to_string(), description: "查看和控制 Windows 服务".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "psservice.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "pssuspend".to_string(), name: "PsSuspend".to_string(), display_name: "进程挂起".to_string(), category: "进程/任务管理类".to_string(), description: "暂停/恢复进程".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "pssuspend64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "psloggedon".to_string(), name: "PsLoggedOn".to_string(), display_name: "登录用户".to_string(), category: "进程/任务管理类".to_string(), description: "显示本地和通过网络登录到系统的用户".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "PsLoggedon64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "psinfo".to_string(), name: "PsInfo".to_string(), display_name: "系统信息".to_string(), category: "进程/任务管理类".to_string(), description: "获取系统详细信息（OS 版本、补丁、物理/虚拟内存、网卡等）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "PsInfo64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "pspasswd".to_string(), name: "PsPasswd".to_string(), display_name: "密码修改".to_string(), category: "进程/任务管理类".to_string(), description: "批量更改账户密码".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "pspasswd64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "psgetsid".to_string(), name: "PsGetSid".to_string(), display_name: "SID查询".to_string(), category: "进程/任务管理类".to_string(), description: "显示计算机或用户的 SID（安全标识符）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "PsGetsid64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },

        // ========== 远程管理类 ==========
        Tool { id: "psexec".to_string(), name: "PsExec".to_string(), display_name: "远程执行".to_string(), category: "远程管理类".to_string(), description: "在远程计算机上执行进程（无需安装代理）".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "PsExec64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "psfile".to_string(), name: "PsFile".to_string(), display_name: "远程文件".to_string(), category: "远程管理类".to_string(), description: "查看远程计算机上被打开的文件".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "psfile64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "psloglist".to_string(), name: "PsLogList".to_string(), display_name: "事件日志".to_string(), category: "远程管理类".to_string(), description: "转储本地或远程计算机的事件日志".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "psloglist64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "psping".to_string(), name: "PsPing".to_string(), display_name: "网络测试".to_string(), category: "远程管理类".to_string(), description: "测量网络延迟和带宽性能，支持 TCP/UDP Ping".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "psping64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "psshutdown".to_string(), name: "PsShutdown".to_string(), display_name: "远程关机".to_string(), category: "远程管理类".to_string(), description: "关闭或重启本地/远程计算机".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "psshutdown.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },

        // ========== 文件/磁盘工具 ==========
        Tool { id: "disk2vhd".to_string(), name: "Disk2vhd".to_string(), display_name: "磁盘转VHD".to_string(), category: "文件/磁盘工具".to_string(), description: "将物理磁盘实时转换为 VHD/VHDX 虚拟磁盘文件，用于 Hyper-V 虚拟机".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "disk2vhd.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "diskext".to_string(), name: "DiskExt".to_string(), display_name: "磁盘扩展".to_string(), category: "文件/磁盘工具".to_string(), description: "查看磁盘分区信息".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "diskext64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "diskmon".to_string(), name: "DiskMon".to_string(), display_name: "硬盘哨兵".to_string(), category: "文件/磁盘工具".to_string(), description: "捕获所有硬盘读写活动，也可作为托盘区硬盘活动指示灯".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "diskmon.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "diskview".to_string(), name: "DiskView".to_string(), display_name: "硬盘检测".to_string(), category: "文件/磁盘工具".to_string(), description: "图形化查看磁盘扇区占用情况".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "DiskView.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "contig".to_string(), name: "Contig".to_string(), display_name: "磁盘测速".to_string(), category: "文件/磁盘工具".to_string(), description: "对单个文件进行碎片整理，或创建指定大小的连续新文件".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "Contig64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "sync".to_string(), name: "Sync".to_string(), display_name: "缓存同步".to_string(), category: "文件/磁盘工具".to_string(), description: "强制将磁盘写缓存中的数据刷新到物理磁盘".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "sync64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "pendmoves".to_string(), name: "PendMoves".to_string(), display_name: "待处理移动".to_string(), category: "文件/磁盘工具".to_string(), description: "查看已安排的待处理文件操作".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "pendmoves64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "ntfsinfo".to_string(), name: "NTFSInfo".to_string(), display_name: "NTFS信息".to_string(), category: "文件/磁盘工具".to_string(), description: "查看 NTFS 卷的结构信息，如主文件表（MFT）大小和位置".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "ntfsinfo64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "volumeid".to_string(), name: "VolumeId".to_string(), display_name: "卷标修改".to_string(), category: "文件/磁盘工具".to_string(), description: "修改 FAT/NTFS 分区的卷序列号".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "Volumeid64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "du".to_string(), name: "Disk Usage".to_string(), display_name: "磁盘用量".to_string(), category: "文件/磁盘工具".to_string(), description: "按目录统计磁盘空间占用".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "du64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "findlinks".to_string(), name: "FindLinks".to_string(), display_name: "硬链接查找".to_string(), category: "文件/磁盘工具".to_string(), description: "查找文件的硬链接".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "FindLinks64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "streams".to_string(), name: "Streams".to_string(), display_name: "ADS流查看".to_string(), category: "文件/磁盘工具".to_string(), description: "显示和管理 NTFS 备用数据流（ADS）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "streams64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "junction".to_string(), name: "Junction".to_string(), display_name: "联接点管理".to_string(), category: "文件/磁盘工具".to_string(), description: "创建和管理 NTFS 交接点（Junction Point）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "junction64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "movefile".to_string(), name: "MoveFile".to_string(), display_name: "重启移动".to_string(), category: "文件/磁盘工具".to_string(), description: "安排文件在下次系统重启时移动/删除".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "movefile64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "pagedfrg".to_string(), name: "PageDefrag".to_string(), display_name: "页面整理".to_string(), category: "文件/磁盘工具".to_string(), description: "页面文件碎片整理".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "pagedfrg.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },

        // ========== 安全/权限类 ==========
        Tool { id: "accesschk".to_string(), name: "AccessChk".to_string(), display_name: "权限检查".to_string(), category: "安全/权限类".to_string(), description: "查看指定用户/组对注册表项、文件、服务、进程等对象的权限".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "accesschk64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "accessenum".to_string(), name: "AccessEnum".to_string(), display_name: "权限枚举".to_string(), category: "安全/权限类".to_string(), description: "快速扫描目录/注册表，显示哪些用户访问了哪些资源，帮助找出权限漏洞".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "AccessEnum.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "shareenum".to_string(), name: "ShareEnum".to_string(), display_name: "共享枚举".to_string(), category: "安全/权限类".to_string(), description: "扫描网络中的共享文件夹及其权限设置，发现共享安全隐患".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "ShareEnum.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "efsdump".to_string(), name: "EFSDump".to_string(), display_name: "EFS查看".to_string(), category: "安全/权限类".to_string(), description: "查看加密文件的信息".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "efsdump.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "regdelnull".to_string(), name: "RegDelNull".to_string(), display_name: "空键删除".to_string(), category: "安全/权限类".to_string(), description: "删除包含嵌入式空字符（Null）的注册表项".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "RegDelNull64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "sigcheck".to_string(), name: "Sigcheck".to_string(), display_name: "系统修复".to_string(), category: "安全/权限类".to_string(), description: "检查文件数字签名、版本信息，校验哈希值，可扫描未签名文件".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "sigcheck64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },

        // ========== 系统信息类 ==========
        Tool { id: "bginfo".to_string(), name: "BgInfo".to_string(), display_name: "系统美化".to_string(), category: "系统信息类".to_string(), description: "将系统 IP、主机名、磁盘空间等信息直接显示在桌面壁纸上".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "Bginfo64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "coreinfo".to_string(), name: "Coreinfo".to_string(), display_name: "CPU检测".to_string(), category: "系统信息类".to_string(), description: "显示 CPU 功能、缓存拓扑、NUMA 信息等".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "coreinfo.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "clockres".to_string(), name: "ClockRes".to_string(), display_name: "时钟分辨率".to_string(), category: "系统信息类".to_string(), description: "显示系统时钟分辨率和定时器最大精度".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "Clockres64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "listdlls".to_string(), name: "ListDLLs".to_string(), display_name: "DLL列表".to_string(), category: "系统信息类".to_string(), description: "列出当前加载的所有 DLL 及其完整路径和版本号".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "Listdlls64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "handle".to_string(), name: "Handle".to_string(), display_name: "文件大师".to_string(), category: "系统信息类".to_string(), description: "显示哪些进程打开了哪些文件或句柄".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "handle64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "logonsessions".to_string(), name: "LogonSessions".to_string(), display_name: "登录会话".to_string(), category: "系统信息类".to_string(), description: "列出系统中当前活动的登录会话".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "logonsessions64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "pipelist".to_string(), name: "PipeList".to_string(), display_name: "管道列表".to_string(), category: "系统信息类".to_string(), description: "查看系统命名管道".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "pipelist64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "loadord".to_string(), name: "LoadOrd".to_string(), display_name: "加载顺序".to_string(), category: "系统信息类".to_string(), description: "查看系统设备驱动程序和服务的加载顺序".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "LoadOrd64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "rammap".to_string(), name: "RAMMap".to_string(), display_name: "内存检测".to_string(), category: "系统信息类".to_string(), description: "高级物理内存分析工具，以多种维度展示内存使用情况".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "RAMMap.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "vmmap".to_string(), name: "VMMap".to_string(), display_name: "虚拟内存".to_string(), category: "系统信息类".to_string(), description: "分析单个进程的虚拟内存分配情况".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "vmmap.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "cacheset".to_string(), name: "CacheSet".to_string(), display_name: "缓存设置".to_string(), category: "系统信息类".to_string(), description: "设置工作集缓存大小".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "cacheset.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "loadordc".to_string(), name: "LoadOrdC".to_string(), display_name: "加载顺序C".to_string(), category: "系统信息类".to_string(), description: "查看系统设备驱动程序和服务的加载顺序（控制台版）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "LoadOrdC64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "portmon".to_string(), name: "PortMon".to_string(), display_name: "端口监控".to_string(), category: "系统信息类".to_string(), description: "监控串口和并口活动".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "portmon.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "ctrl2cap".to_string(), name: "Ctrl2cap".to_string(), display_name: "键盘重映射".to_string(), category: "系统信息类".to_string(), description: "将 Caps Lock 键映射为 Ctrl 键（内核级过滤驱动示例）".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "ctrl2cap.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },

        // ========== 网络类 ==========
        Tool { id: "tcpview".to_string(), name: "TCPView".to_string(), display_name: "无线监测".to_string(), category: "网络类".to_string(), description: "实时查看所有 TCP 和 UDP 连接，显示关联进程、源/目标 IP、端口及连接状态".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "tcpview.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "tcpvcon".to_string(), name: "Tcpvcon".to_string(), display_name: "TCP控制台".to_string(), category: "网络类".to_string(), description: "TCPView 的命令行版本".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "tcpvcon.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "whois".to_string(), name: "Whois".to_string(), display_name: "WHOIS查询".to_string(), category: "网络类".to_string(), description: "查询域名注册信息".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "whois64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },

        // ========== 注册表类 ==========
        Tool { id: "regjump".to_string(), name: "RegJump".to_string(), display_name: "注册表项".to_string(), category: "注册表类".to_string(), description: "跳转到指定注册表路径".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "regjump.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "ru".to_string(), name: "RU".to_string(), display_name: "注册表用量".to_string(), category: "注册表类".to_string(), description: "查看注册表空间使用情况".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "ru64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },

        // ========== Active Directory ==========
        Tool { id: "adexplorer".to_string(), name: "ADExplorer".to_string(), display_name: "AD浏览".to_string(), category: "Active Directory".to_string(), description: "Active Directory 图形化浏览器和编辑器".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "adexplorer.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "adinsight".to_string(), name: "AdInsight".to_string(), display_name: "AD监控".to_string(), category: "Active Directory".to_string(), description: "LDAP 实时监控工具，用于排查 AD 通信问题".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "adinsight.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "adrestore".to_string(), name: "ADRestore".to_string(), display_name: "AD恢复".to_string(), category: "Active Directory".to_string(), description: "恢复已删除的 AD 对象".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "adrestore.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },

        // ========== 调试/诊断类 ==========
        Tool { id: "dbgview".to_string(), name: "DebugView".to_string(), display_name: "活动视图".to_string(), category: "调试/诊断类".to_string(), description: "捕获驱动程序 DbgPrint 和 Win32 OutputDebugString 的输出".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "Dbgview.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "livekd".to_string(), name: "LiveKd".to_string(), display_name: "内核调试".to_string(), category: "调试/诊断类".to_string(), description: "在运行系统上使用内核调试器".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "livekd64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "procdump".to_string(), name: "ProcDump".to_string(), display_name: "进程转储".to_string(), category: "调试/诊断类".to_string(), description: "按触发条件捕获进程内存转储（Dump）".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "procdump64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "strings".to_string(), name: "Strings".to_string(), display_name: "文件搜索".to_string(), category: "调试/诊断类".to_string(), description: "从二进制文件中搜索 ANSI/Unicode 字符串".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "strings64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "winobj".to_string(), name: "WinObj".to_string(), display_name: "对象管理".to_string(), category: "调试/诊断类".to_string(), description: "查看 Windows 内核对象命名空间".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "winobj.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "hex2dec".to_string(), name: "Hex2Dec".to_string(), display_name: "进制转换".to_string(), category: "调试/诊断类".to_string(), description: "十六进制与十进制相互转换".to_string(), risk_level: "safe".to_string(), ui_type: "cli".to_string(), preferred_exe: "hex2dec64.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },

        // ========== 其他工具 ==========
        Tool { id: "autologon".to_string(), name: "Autologon".to_string(), display_name: "自动登录".to_string(), category: "其他工具".to_string(), description: "配置 Windows 自动登录，跳过密码输入界面".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "autologon.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "autoruns".to_string(), name: "Autoruns".to_string(), display_name: "启动管理".to_string(), category: "其他工具".to_string(), description: "显示系统启动和用户登录时自动运行的所有程序、驱动、服务等，支持直接禁用/删除".to_string(), risk_level: "admin".to_string(), ui_type: "gui".to_string(), preferred_exe: "Autoruns64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
        Tool { id: "desktops".to_string(), name: "Desktops".to_string(), display_name: "虚拟桌面".to_string(), category: "其他工具".to_string(), description: "创建多个虚拟桌面".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "desktops.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "zoomit".to_string(), name: "ZoomIt".to_string(), display_name: "演示工具".to_string(), category: "其他工具".to_string(), description: "屏幕缩放、标注和演示计时器".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "ZoomIt.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "shellrunas".to_string(), name: "ShellRunas".to_string(), display_name: "右键提权".to_string(), category: "其他工具".to_string(), description: "在资源管理器右键菜单中添加「以其他用户身份运行」功能".to_string(), risk_level: "safe".to_string(), ui_type: "gui".to_string(), preferred_exe: "shellrunas.exe".to_string(), requires_admin: false, enabled: true, exists_on_disk: false },
        Tool { id: "autorunsc".to_string(), name: "AutorunsC".to_string(), display_name: "启动管理C".to_string(), category: "其他工具".to_string(), description: "Autoruns 的命令行版本，显示和管理系统启动项".to_string(), risk_level: "admin".to_string(), ui_type: "cli".to_string(), preferred_exe: "autorunsc64.exe".to_string(), requires_admin: true, enabled: true, exists_on_disk: false },
    ];

    for tool in &mut tools {
        tool.exists_on_disk = root.join(&tool.preferred_exe).exists();
    }

    // Apply security policy: disable tools in the disabled_tools list
    let policy = load_security_policy();
    for tool in &mut tools {
        if policy.disabled_tools.contains(&tool.id) {
            tool.enabled = false;
        }
    }

    // Append Windowsbat tools
    if let Ok(bat_tools) = scan_windowsbat_tools() {
        tools.extend(bat_tools);
    }

    Ok(tools)
}

fn scan_windowsbat_tools() -> Result<Vec<Tool>, String> {
    let tools_root = get_tools_root_path();
    let windowsbat_dir = PathBuf::from(&tools_root)
        .parent()
        .map(|p| p.join("Windowsbat"))
        .unwrap_or_else(|| PathBuf::from("Windowsbat"));

    let mut bat_tools = Vec::new();

    if !windowsbat_dir.exists() {
        return Ok(bat_tools);
    }

    let entries = fs::read_dir(&windowsbat_dir)
        .map_err(|e| format!("无法读取 Windowsbat 目录: {}", e))?;

    for entry in entries {
        let entry = entry.map_err(|e| format!("读取目录项失败: {}", e))?;
        let path = entry.path();
        let name = entry.file_name();
        let name_str = name.to_string_lossy();

        if !name_str.ends_with(".bat") {
            continue;
        }

        let id = name_str.trim_end_matches(".bat").to_string();
        // display_name: strip leading "NN_" prefix (e.g. "01_右键菜单设置" -> "右键菜单设置")
        let display_name = id
            .trim_start_matches(|c: char| c.is_ascii_digit())
            .trim_start_matches('_')
            .to_string();

        let description = match display_name.as_str() {
            "右键菜单设置" => "切换 Windows 10/11 右键菜单、添加/删除超级菜单、Hash 校验菜单",
            "桌面设置" => "隐藏/显示桌面小箭头、Windows 聚焦、壁纸管理、Bing 壁纸、版本水印",
            "任务栏设置" => "一键净化任务栏、小组件开关、任务视图、搜索、自动隐藏、时间秒数",
            "资源管理器设置" => "默认路径、扩展名开关、单击双击、隐藏文件、U 盘、导航栏、缓存清理",
            "Windows更新设置" => "暂停 Windows 更新至 2999 年、恢复更新",
            "UAC设置" => "从不通知、恢复默认、彻底关闭/启用 UAC",
            "系统设置集中管理" => "打开上帝模式控制面板（所有系统设置集中一处）",
            "WIFI密码" => "显示本机所有已连接过的 WiFi 名称及密码",
            "电源管理" => "定时关机/重启/休眠、禁用自动睡眠、启用/禁用休眠",
            "应用管理" => "一键卸载预装应用、OneDrive 安装/卸载、微软拼音输入法设置",
            "编辑Hosts" => "以管理员权限打开 hosts 文件",
            "网络管理" => "网络信息、DNS、Ping、路由追踪、端口、防火墙、代理、端口转发",
            "设备管理" => "禁用/启用照相机、蓝牙",
            "Hash计算" => "计算文件 MD5/SHA1/SHA256/SHA512 等哈希值",
            _ => "Windowsbat 批处理脚本",
        };

        bat_tools.push(Tool {
            id: id.clone(),
            name: display_name.clone(),
            display_name,
            category: "Windowsbat".to_string(),
            description: description.to_string(),
            risk_level: "admin".to_string(),
            ui_type: "bat".to_string(),
            preferred_exe: name_str.to_string(),
            requires_admin: true,
            enabled: true,
            exists_on_disk: path.exists(),
        });
    }

    // Sort by id (numeric prefix)
    bat_tools.sort_by(|a, b| a.id.cmp(&b.id));

    Ok(bat_tools)
}

#[tauri::command]
pub fn get_tool_catalog() -> Result<Vec<Tool>, String> {
    scan_tools()
}

#[tauri::command]
pub fn launch_tool(tool_id: String, args: Option<String>) -> Result<LaunchResult, String> {
    let tools = scan_tools()?;
    let tool = tools.iter().find(|t| t.id == tool_id)
        .ok_or_else(|| "Tool not found".to_string())?;

    if !tool.enabled {
        return Ok(LaunchResult {
            success: false,
            message: "该工具已被禁用".to_string(),
            pid: None,
        });
    }

    let tools_root = get_tools_root_path();
    let tools_root_canonical = PathBuf::from(&tools_root)
        .canonicalize()
        .map_err(|e| format!("无法解析工具根目录: {}", e))?;

    // Determine actual executable path
    let (exe_path, is_bat, bat_root_canonical) = if tool.preferred_exe.ends_with(".bat") {
        let bat_dir = PathBuf::from(&tools_root)
            .parent()
            .map(|p| p.join("Windowsbat"))
            .unwrap_or_else(|| PathBuf::from("Windowsbat"));
        let bat_root = bat_dir.canonicalize()
            .map_err(|e| format!("无法解析 BAT 根目录: {}", e))?;
        let bat_path = bat_dir.join(&tool.preferred_exe);
        (bat_path, true, Some(bat_root))
    } else {
        (PathBuf::from(&tools_root).join(&tool.preferred_exe), false, None)
    };

    if !exe_path.exists() {
        return Ok(LaunchResult {
            success: false,
            message: format!("工具文件不存在: {}", exe_path.display()),
            pid: None,
        });
    }

    // Path traversal check — applies to ALL file types including BAT
    let exe_canonical = exe_path.canonicalize()
        .map_err(|e| format!("无法解析工具路径: {}", e))?;
    let in_tools_root = exe_canonical.starts_with(&tools_root_canonical);
    let in_bat_root = bat_root_canonical
        .as_ref()
        .map(|r| exe_canonical.starts_with(r))
        .unwrap_or(false);
    if !in_tools_root && !in_bat_root {
        return Ok(LaunchResult {
            success: false,
            message: "路径安全检查失败: 工具文件不在指定的根目录内".to_string(),
            pid: None,
        });
    }

    // Argument validation
    let validated_args = match args {
        Some(ref args_str) if !args_str.trim().is_empty() => {
            let parts: Vec<&str> = args_str.split_whitespace().collect();
            if let Some(bad) = parts.iter().find(|a| !is_safe_arg(a)) {
                return Ok(LaunchResult {
                    success: false,
                    message: format!("参数包含非法字符: {}", bad),
                    pid: None,
                });
            }
            parts.into_iter().map(String::from).collect::<Vec<_>>()
        }
        _ => Vec::new(),
    };

    if is_bat {
        let bat_path_str = exe_path.to_string_lossy().to_string();
        // Use ShellExecuteExW with "runas" verb to launch .bat directly with admin rights.
        // This avoids any intermediate console window — Windows handles the elevation natively.
        #[cfg(windows)]
        {
            return match windows_shell::execute_as_admin(&bat_path_str) {
                Ok(()) => Ok(LaunchResult {
                    success: true,
                    message: format!("已启动: {} (管理员权限)", tool.display_name),
                    pid: None,
                }),
                Err(e) => Ok(LaunchResult {
                    success: false,
                    message: format!("启动失败: {} | 路径: {}", e, exe_path.display()),
                    pid: None,
                }),
            };
        }
        #[cfg(not(windows))]
        {
            return Ok(LaunchResult {
                success: false,
                message: "批处理仅在 Windows 上支持".to_string(),
                pid: None,
            });
        }
    }

    let child_result = {
        let mut cmd = Command::new(&exe_path);
        if !validated_args.is_empty() {
            cmd.args(&validated_args);
        }
        cmd.spawn()
    };

    match child_result {
        Ok(child) => {
            Ok(LaunchResult {
                success: true,
                message: format!("已启动: {} (PID: {})", tool.display_name, child.id()),
                pid: Some(child.id()),
            })
        }
        Err(e) => {
            Ok(LaunchResult {
                success: false,
                message: format!("启动失败: {} | 路径: {}", e, exe_path.display()),
                pid: None,
            })
        }
    }
}

// Validate command-line argument characters to prevent injection.
fn is_safe_arg(arg: &str) -> bool {
    if arg.is_empty() {
        return true;
    }
    arg.chars().all(|c| {
        c.is_alphanumeric()
            || [' ', '.', '_', '-', '/', '\\', ':', '=', ',', '@', '%', '~']
                .contains(&c)
    }) && !arg.starts_with('|')
        && !arg.starts_with('&')
        && !arg.starts_with(';')
        && !arg.starts_with('>')
        && !arg.starts_with('<')
}

#[tauri::command]
pub fn get_launch_history() -> Result<Vec<String>, String> {
    Ok(vec![])
}

#[tauri::command]
pub fn get_tools_root() -> Result<String, String> {
    Ok(get_tools_root_path())
}

#[tauri::command]
pub fn set_tools_root(path: String) -> Result<(), String> {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return Err("路径不能为空".to_string());
    }
    let path_buf = PathBuf::from(trimmed);
    if !path_buf.exists() {
        return Err("路径不存在".to_string());
    }
    if !path_buf.is_dir() {
        return Err("路径必须是目录".to_string());
    }
    let dir = app_data_dir();
    fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    fs::write(tools_root_file(), trimmed).map_err(|e| e.to_string())?;
    invalidate_caches();
    Ok(())
}

#[tauri::command]
pub fn get_tool_usage(tool_id: String) -> Result<Option<ToolUsage>, String> {
    // Try cache first
    if let Ok(cache) = USAGE_DB_CACHE.lock() {
        if let Some(ref db) = *cache {
            return Ok(db.get(&tool_id).cloned());
        }
    }

    let paths = [
        PathBuf::from(get_tools_root_path()).join("tool_usage.json"),
        PathBuf::from(default_tools_root()).join("tool_usage.json"),
    ];

    for path in &paths {
        match fs::read_to_string(path) {
            Ok(content) => {
                let db: HashMap<String, ToolUsage> =
                    serde_json::from_str(&content).map_err(|e| format!("解析错误: {}", e))?;
                let result = db.get(&tool_id).cloned();
                if let Ok(mut cache) = USAGE_DB_CACHE.lock() {
                    *cache = Some(db);
                }
                return Ok(result);
            }
            Err(_) => continue,
        }
    }
    Ok(None)
}

const MAX_SIGNATURE_FILE_SIZE: u64 = 1024 * 1024 * 1024; // 1 GB

pub fn calculate_sha256(path: &PathBuf) -> Result<String, Box<dyn std::error::Error>> {
    let metadata = fs::metadata(path)?;
    if metadata.len() > MAX_SIGNATURE_FILE_SIZE {
        return Err("文件过大，无法进行签名验证".into());
    }
    let mut file = fs::File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 8192];
    loop {
        let n = file.read(&mut buffer)?;
        if n == 0 {
            break;
        }
        hasher.update(&buffer[..n]);
    }
    Ok(hex::encode(hasher.finalize()))
}

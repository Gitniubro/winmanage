use crate::commands::util::command_output;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::time::{SystemTime, UNIX_EPOCH};
use sysinfo::{Disks, System};
use winreg::enums::{HKEY_LOCAL_MACHINE, KEY_READ};
use winreg::RegKey;

#[derive(Serialize, Deserialize, Debug)]
pub struct SystemInfo {
    pub os_name: String,
    pub os_version: String,
    pub system_dir: String,
    pub hostname: String,
    pub username: String,
    pub workgroup: String,
    pub cpu_name: String,
    pub cpu_cores: usize,
    pub memory_total: u64,
    pub memory_used: u64,
    pub virtual_memory: String,
    pub bios: String,
    pub mainboard: String,
    pub sound_card: String,
    pub network_card: String,
    pub gpu: String,
    pub disk_model: String,
    pub optical_drive: String,
    pub display: String,
    pub keyboard: String,
    pub mouse: String,
    pub camera: String,
    pub printer: String,
    pub disks: Vec<DiskInfo>,
    pub networks: Vec<NetworkInfo>,
    pub local_ip: String,
    pub gateway_ip: String,
    pub uptime: String,
    pub current_time: String,
    pub lunar_date: String,
    pub week_text: String,
    pub day_of_year: String,
    pub resolution: String,
    pub process_count: usize,
    pub browser_runtime: String,
    pub install_date: String,
    pub last_shutdown: String,
    pub boot_time: String,
    pub computer_type: String,
    pub app_platform: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct DiskInfo {
    pub name: String,
    pub mount_point: String,
    pub total: u64,
    pub used: u64,
    pub available: u64,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct NetworkInfo {
    pub name: String,
    pub description: String,
    pub mac: String,
    pub ip: String,
    pub status: String,
}

#[tauri::command]
pub fn get_system_info() -> Result<SystemInfo, String> {
    let mut sys = System::new_all();
    sys.refresh_all();

    let cim = collect_cim_snapshot();
    let ipconfig = command_output("ipconfig", &["/all"], 1200).unwrap_or_default();

    let product_name = reg_string(
        r"SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "ProductName",
    )
    .or_else(System::long_os_version)
    .unwrap_or_else(|| "Windows".to_string());
    let build = reg_string(
        r"SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "CurrentBuildNumber",
    )
    .or_else(|| reg_string(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CurrentBuild"))
    .unwrap_or_else(unknown);
    let ubr = reg_u32(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "UBR");
    let display_version = reg_string(
        r"SOFTWARE\Microsoft\Windows NT\CurrentVersion",
        "DisplayVersion",
    )
    .or_else(|| reg_string(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ReleaseId"));

    let os_version = match (display_version, ubr) {
        (Some(version), Some(ubr)) if known(&build) => format!("{version} ({build}.{ubr})"),
        (Some(version), _) if known(&build) => format!("{version} ({build})"),
        (_, Some(ubr)) if known(&build) => format!("{build}.{ubr}"),
        _ => System::os_version().unwrap_or_else(unknown),
    };

    let system_root = std::env::var("SystemRoot")
        .ok()
        .or_else(|| reg_string(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "SystemRoot"))
        .unwrap_or_else(|| "C:\\Windows".to_string());

    let wmi_disk_models: Vec<String> = cim.get("DiskDrive")
        .and_then(|v| v.as_array())
        .map(|arr| arr.iter().filter_map(|item| json_string(item, "Model")).collect())
        .unwrap_or_default();

    let volume_disks: Vec<DiskInfo> = Disks::new_with_refreshed_list()
        .iter()
        .enumerate()
        .map(|(idx, disk)| {
            let mount = disk.mount_point().to_string_lossy().to_string();
            // Windows mount_point like "C:\\", normalize to "C:"
            let mount_point = mount.trim_end_matches('\\').to_string();
            let name = wmi_disk_models.get(idx)
                .cloned()
                .filter(|n| known(n))
                .unwrap_or_else(|| mount_point.clone());
            let total = disk.total_space();
            let available = disk.available_space();
            DiskInfo {
                name,
                mount_point,
                total,
                used: total.saturating_sub(available),
                available,
            }
        })
        .collect();

    let networks = collect_network_adapters();

    let uptime_seconds = System::uptime();
    let (mut local_ip, gateway_ip) = parse_ipconfig(&ipconfig);
    // 回退：如果 ipconfig 没取到 IP，从 networks 列表中取第一个有效 IP
    if !known(&local_ip) {
        local_ip = networks.iter()
            .find(|n| !n.ip.is_empty() && n.status == "Connected")
            .map(|n| n.ip.clone())
            .unwrap_or_else(unknown);
    }
    let computer = cim_object(&cim, "ComputerSystem");
    let os = cim_object(&cim, "OperatingSystem");

    // PnP fallback lookups
    let pnp_sound = pnp_names(&cim, &["MEDIA", "Audio", "声音", "音频", "Sound"]);
    let pnp_display = pnp_names(&cim, &["MONITOR", "Display", "显示", "监视器"]);
    let pnp_keyboard = pnp_names(&cim, &["KEYBOARD", "键盘"]);
    let pnp_mouse = pnp_names(&cim, &["MOUSE", "Pointing", "鼠标", "HID-compliant"]);
    let pnp_camera = pnp_names(&cim, &["CAMERA", "Image", "摄像", "扫描", "Scanner"]);

    let bios = join_non_empty(vec![
        reg_string(r"HARDWARE\DESCRIPTION\System\BIOS", "BIOSVendor"),
        reg_string(r"HARDWARE\DESCRIPTION\System\BIOS", "BIOSVersion"),
        reg_string(r"HARDWARE\DESCRIPTION\System\BIOS", "BIOSReleaseDate"),
    ])
    .or_else(|| {
        join_non_empty(vec![
            cim_string(&cim, "BIOS", "Manufacturer"),
            cim_string(&cim, "BIOS", "SMBIOSBIOSVersion"),
            cim_string(&cim, "BIOS", "ReleaseDate").map(|value| cim_date_to_text(&value)),
        ])
    })
    .unwrap_or_else(unknown);

    let mainboard = join_non_empty(vec![
        reg_string(r"HARDWARE\DESCRIPTION\System\BIOS", "BaseBoardManufacturer"),
        reg_string(r"HARDWARE\DESCRIPTION\System\BIOS", "BaseBoardProduct"),
    ])
    .or_else(|| {
        join_non_empty(vec![
            cim_string(&cim, "BaseBoard", "Manufacturer"),
            cim_string(&cim, "BaseBoard", "Product"),
        ])
    })
    .unwrap_or_else(unknown);

    let cpu_name = sys
        .cpus()
        .first()
        .map(|cpu| cpu.brand().to_string())
        .filter(|value| known(value))
        .unwrap_or_else(unknown);

    let physical_disk = cim_names(&cim, "DiskDrive", "Model").unwrap_or_else(|| {
        volume_disks
            .first()
            .map(|disk| disk.name.clone())
            .unwrap_or_else(unknown)
    });

    Ok(SystemInfo {
        os_name: product_name,
        os_version,
        system_dir: format!("{system_root}\\system32"),
        hostname: System::host_name().unwrap_or_else(unknown),
        username: std::env::var("USERNAME").unwrap_or_else(|_| unknown()),
        workgroup: computer
            .and_then(|value| json_string(value, "Workgroup").or_else(|| json_string(value, "Domain")))
            .or_else(|| std::env::var("USERDOMAIN").ok())
            .unwrap_or_else(unknown),
        cpu_name,
        cpu_cores: sys.cpus().len(),
        memory_total: sys.total_memory(),
        memory_used: sys.used_memory(),
        virtual_memory: page_file_info(&cim),
        bios,
        mainboard,
        sound_card: cim_names(&cim, "SoundDevice", "Name")
            .or_else(|| pnp_sound.clone())
            .unwrap_or_else(unknown),
        network_card: cim_names(&cim, "NetworkAdapter", "Name")
            .or_else(|| {
                networks
                    .first()
                    .map(|network| network.name.clone())
            })
            .unwrap_or_else(unknown),
        gpu: cim_names(&cim, "VideoController", "Name").unwrap_or_else(unknown),
        disk_model: physical_disk.clone(),
        optical_drive: cim_names(&cim, "CDROMDrive", "Name").unwrap_or_else(unknown),
        display: cim_names(&cim, "DesktopMonitor", "Name")
            .or_else(|| pnp_display.clone())
            .unwrap_or_else(unknown),
        keyboard: cim_names(&cim, "Keyboard", "Name")
            .or_else(|| pnp_keyboard.clone())
            .unwrap_or_else(unknown),
        mouse: cim_names(&cim, "PointingDevice", "Name")
            .or_else(|| pnp_mouse.clone())
            .unwrap_or_else(unknown),
        camera: cim_names(&cim, "Camera", "Name")
            .or_else(|| pnp_camera.clone())
            .unwrap_or_else(unknown),
        printer: cim_names(&cim, "Printer", "Name").unwrap_or_else(unknown),
        disks: volume_disks,
        networks,
        local_ip,
        gateway_ip: if known(&gateway_ip) { gateway_ip } else { gateway_from_wmic() },
        uptime: format_duration(uptime_seconds),
        current_time: "由前端实时显示".to_string(),
        lunar_date: get_lunar_date(),
        week_text: week_day_text(),
        day_of_year: day_of_year_text(),
        resolution: resolution(&cim),
        process_count: sys.processes().len(),
        browser_runtime: webview_runtime(),
        install_date: os
            .and_then(|value| json_string(value, "InstallDate"))
            .map(|value| cim_date_to_text(&value))
            .or_else(|| {
                reg_u32(r"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "InstallDate")
                    .and_then(|s| unix_timestamp_to_chinese_date(s))
            })
            .unwrap_or_else(unknown),
        last_shutdown: last_shutdown_time(),
        boot_time: os
            .and_then(|value| json_string(value, "LastBootUpTime"))
            .map(|value| cim_date_to_text(&value))
            .unwrap_or_else(|| approximate_boot_time(uptime_seconds)),
        computer_type: computer_type(computer),
        app_platform: "Windows 7、10、11".to_string(),
    })
}

fn collect_cim_snapshot() -> Value {
    let script = r#"
$ErrorActionPreference='SilentlyContinue';
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
function FirstObj($class,$props){
    $r = $null
    try { $r = Get-CimInstance -ClassName $class | Select-Object -First 1 -Property $props } catch {}
    if (-not $r) { try { $r = Get-WmiObject -Class $class | Select-Object -First 1 -Property $props } catch {} }
    return $r
}
function ListObj($class,$props){
    $r = @()
    try { $r = @(Get-CimInstance -ClassName $class | Select-Object -First 4 -Property $props) } catch {}
    if ($r.Count -eq 0) { try { $r = @(Get-WmiObject -Class $class | Select-Object -First 4 -Property $props) } catch {} }
    return $r
}
$os = FirstObj 'Win32_OperatingSystem' @('InstallDate','LastBootUpTime');
$installDate = if ($os.InstallDate) { $os.InstallDate.ToString('yyyy-MM-dd HH:mm:ss') } else { $null };
$bootTime = if ($os.LastBootUpTime) { $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss') } else { $null };
$data=[ordered]@{
  ComputerSystem=FirstObj 'Win32_ComputerSystem' @('Manufacturer','Model','SystemType','Domain','Workgroup','PCSystemType');
  OperatingSystem=@{InstallDate=$installDate;LastBootUpTime=$bootTime};
  BIOS=FirstObj 'Win32_BIOS' @('Manufacturer','SMBIOSBIOSVersion','ReleaseDate');
  BaseBoard=FirstObj 'Win32_BaseBoard' @('Manufacturer','Product');
  VideoController=ListObj 'Win32_VideoController' @('Name','CurrentHorizontalResolution','CurrentVerticalResolution','CurrentRefreshRate','VideoProcessor');
  SoundDevice=ListObj 'Win32_SoundDevice' @('Name','Manufacturer');
  NetworkAdapter=@(Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -and $_.NetEnabled } | Select-Object -First 4 -Property Name);
  DiskDrive=ListObj 'Win32_DiskDrive' @('Model');
  CDROMDrive=ListObj 'Win32_CDROMDrive' @('Name');
  DesktopMonitor=ListObj 'Win32_DesktopMonitor' @('Name','ScreenWidth','ScreenHeight');
  Keyboard=ListObj 'Win32_Keyboard' @('Name','Description');
  PointingDevice=ListObj 'Win32_PointingDevice' @('Name','Description');
  Printer=ListObj 'Win32_Printer' @('Name');
  Camera=@(Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Camera' -or $_.Name -match 'Camera|Scanner|摄像|扫描' } | Select-Object -First 4 -Property Name);
  PageFileSetting=ListObj 'Win32_PageFileSetting' @('Name','InitialSize','MaximumSize');
  PnPDevices=@(Get-CimInstance Win32_PnPEntity | Where-Object { $_.Status -eq 'OK' } | Select-Object -First 20 -Property Name,PNPClass)
};
$data | ConvertTo-Json -Compress -Depth 4
"#;

    command_output(
        "powershell",
        &[
            "-NoProfile",
            "-NonInteractive",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            script,
        ],
        20000,
    )
    .and_then(|raw| serde_json::from_str::<Value>(&raw).ok())
    .unwrap_or(Value::Null)
}

fn reg_key(path: &str) -> Option<RegKey> {
    RegKey::predef(HKEY_LOCAL_MACHINE)
        .open_subkey_with_flags(path, KEY_READ)
        .ok()
}

fn reg_string(path: &str, name: &str) -> Option<String> {
    reg_key(path)
        .and_then(|key| key.get_value::<String, _>(name).ok())
        .map(|value| value.trim().to_string())
        .filter(|value| known(value))
}

fn reg_u32(path: &str, name: &str) -> Option<u32> {
    reg_key(path).and_then(|key| key.get_value::<u32, _>(name).ok())
}

fn cim_object<'a>(root: &'a Value, name: &str) -> Option<&'a Value> {
    root.get(name).and_then(|value| {
        if value.is_array() {
            value.as_array().and_then(|items| items.first())
        } else if value.is_object() {
            Some(value)
        } else {
            None
        }
    })
}

fn cim_string(root: &Value, section: &str, key: &str) -> Option<String> {
    cim_object(root, section).and_then(|value| json_string(value, key))
}

fn json_string(value: &Value, key: &str) -> Option<String> {
    value
        .get(key)
        .and_then(|field| {
            if let Some(text) = field.as_str() {
                Some(text.to_string())
            } else if field.is_number() {
                Some(field.to_string())
            } else {
                None
            }
        })
        .map(|text| text.trim().to_string())
        .filter(|text| known(text))
}

fn cim_names(root: &Value, section: &str, key: &str) -> Option<String> {
    let value = root.get(section)?;
    let mut names = Vec::new();
    if let Some(items) = value.as_array() {
        for item in items {
            if let Some(name) = json_string(item, key) {
                names.push(name);
            }
        }
    } else if let Some(name) = json_string(value, key) {
        names.push(name);
    }

    names.dedup();
    let joined = names.into_iter().take(3).collect::<Vec<_>>().join(" / ");
    if known(&joined) {
        Some(joined)
    } else {
        None
    }
}

fn parse_ipconfig(raw: &str) -> (String, String) {
    let mut local_ip = None;
    let mut gateway_ip = None;
    let mut gateway_pending = false;

    for line in raw.lines() {
        let trimmed = line.trim();
        let value = trimmed
            .split_once(':')
            .map(|(_, value)| value.trim())
            .unwrap_or(trimmed)
            .trim_matches('.');

        if (trimmed.contains("IPv4") || trimmed.contains("IP Address")) && local_ip.is_none() {
            local_ip = extract_ipv4(value);
        }
        if trimmed.contains("Default Gateway") || trimmed.contains("默认网关") {
            gateway_ip = extract_ipv4(value);
            gateway_pending = gateway_ip.is_none();
            continue;
        }
        if gateway_pending {
            gateway_ip = extract_ipv4(value);
            gateway_pending = gateway_ip.is_none();
        }
    }

    (
        local_ip.unwrap_or_else(unknown),
        gateway_ip.unwrap_or_else(unknown),
    )
}

fn extract_ipv4(text: &str) -> Option<String> {
    text.split_whitespace()
        .map(|part| part.trim_matches(|ch: char| !ch.is_ascii_digit() && ch != '.'))
        .find(|part| {
            let parts: Vec<&str> = part.split('.').collect();
            parts.len() == 4
                && parts
                    .iter()
                    .all(|segment| !segment.is_empty() && segment.parse::<u8>().is_ok())
        })
        .map(str::to_string)
}

fn resolution(root: &Value) -> String {
    let mut parts = Vec::new();
    if let Some(video) = cim_object(root, "VideoController") {
        let width = json_string(video, "CurrentHorizontalResolution");
        let height = json_string(video, "CurrentVerticalResolution");
        if let (Some(w), Some(h)) = (width, height) {
            parts.push(format!("{w} x {h}"));
        }
        if let Some(rate) = json_string(video, "CurrentRefreshRate") {
            parts.push(format!("{rate}赫兹"));
        }
    }
    if parts.is_empty() {
        if let Some(monitor) = cim_object(root, "DesktopMonitor") {
            let width = json_string(monitor, "ScreenWidth");
            let height = json_string(monitor, "ScreenHeight");
            if let (Some(w), Some(h)) = (width, height) {
                parts.push(format!("{w} x {h}"));
            }
        }
    }
    if parts.is_empty() { unknown() } else { parts.join(" ") }
}

fn cim_date_to_text(value: &str) -> String {
    let trimmed = value.trim();
    // ISO format: 2024-08-12T10:43:52 or 2024-08-12 10:43:52
    if trimmed.len() >= 19 && trimmed.chars().nth(4) == Some('-') {
        let dt = trimmed.replace('T', " ");
        return format!(
            "{}年{}月{}日 {}:{}:{}",
            &dt[0..4], &dt[5..7], &dt[8..10],
            &dt[11..13], &dt[14..16], &dt[17..19]
        );
    }
    // CIM_DATETIME format: 20240812104352.000000+480
    if trimmed.len() >= 14 {
        let clean = trimmed.split('.').next().unwrap_or(trimmed);
        if clean.len() >= 14 && clean.chars().next().unwrap_or('0').is_ascii_digit() {
            return format!(
                "{}年{}月{}日 {}:{}:{}",
                &clean[0..4], &clean[4..6], &clean[6..8],
                &clean[8..10], &clean[10..12], &clean[12..14]
            );
        }
    }
    unknown()
}

fn approximate_boot_time(uptime_seconds: u64) -> String {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .ok()
        .map(|duration| duration.as_secs().saturating_sub(uptime_seconds))
        .and_then(|s| unix_timestamp_to_chinese_date(s as u32))
        .unwrap_or_else(unknown)
}

fn computer_type(computer: Option<&Value>) -> String {
    let system_type = computer.and_then(|value| json_string(value, "SystemType"));
    match computer.and_then(|value| json_string(value, "PCSystemType")).as_deref() {
        Some("2") => "移动电脑".to_string(),
        Some("3") => "桌面电脑".to_string(),
        Some("4") => "企业服务器".to_string(),
        Some("5") => "小型服务器".to_string(),
        _ => system_type
            .map(|value| {
                if value.contains("x64") {
                    "Windows x64 桌面电脑".to_string()
                } else {
                    value
                }
            })
            .unwrap_or_else(|| "Windows 桌面电脑".to_string()),
    }
}

fn webview_runtime() -> String {
    reg_string(
        r"SOFTWARE\Microsoft\EdgeUpdate\Clients\{F1E7EE8A-DC05-4C18-B3D2-97C49DB52B7F}",
        "pv",
    )
    .unwrap_or_else(|| "WebView2 Runtime".to_string())
}

fn last_shutdown_time() -> String {
    // 方法一：wevtutil 查询系统事件日志
    let result = command_output(
        "wevtutil",
        &[
            "qe",
            "System",
            "/q:*[System[(EventID=1074 or EventID=6006 or EventID=6008)]]",
            "/c:1",
            "/rd:true",
            "/f:text",
        ],
        5000,
    )
    .and_then(|raw| {
        raw.lines()
            .map(str::trim)
            .find(|line| line.starts_with("Date:") || line.starts_with("日期:"))
            .and_then(|line| line.split_once(':').map(|(_, value)| value.trim().to_string()))
    })
    .map(|value| format_iso_date(&value))
    .filter(|value| known(value));

    // 回退：PowerShell Get-WinEvent 查询
    result.unwrap_or_else(|| {
        command_output(
            "powershell",
            &[
                "-NoProfile",
                "-NonInteractive",
                "-Command",
                "Get-WinEvent -FilterHashtable @{LogName='System'; ID=1074,6006,6008} -MaxEvents 1 -ErrorAction SilentlyContinue | ForEach-Object { $_.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss') }"
            ],
            5000,
        )
        .map(|value| value.trim().to_string())
        .filter(|value| known(value))
        .map(|value| format_iso_date(&value))
        .unwrap_or_else(unknown)
    })
}

fn day_of_year_text() -> String {
    total_days_since_epoch()
        .map(|days| {
            let mut year = 1970i64;
            let mut remaining = days;
            loop {
                let days_in = if (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) {
                    366
                } else {
                    365
                };
                if remaining < days_in {
                    break;
                }
                remaining -= days_in;
                year += 1;
            }
            format!("第{}天", remaining + 1)
        })
        .unwrap_or_else(unknown)
}

fn week_day_text() -> String {
    total_days_since_epoch()
        .map(|days| {
            let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"];
            // 1970-01-01 是周四 (index 4)
            let weekday = ((days + 3) % 7) as usize;
            names[weekday].to_string()
        })
        .unwrap_or_else(unknown)
}

fn total_days_since_epoch() -> Option<u64> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .ok()
        .map(|d| d.as_secs() / 86400)
}

fn join_non_empty(values: Vec<Option<String>>) -> Option<String> {
    let joined = values
        .into_iter()
        .flatten()
        .filter(|value| known(value))
        .collect::<Vec<_>>()
        .join(" ");
    if known(&joined) {
        Some(joined)
    } else {
        None
    }
}

fn page_file_info(root: &Value) -> String {
    let mut items = Vec::new();
    if let Some(value) = root.get("PageFileSetting") {
        if let Some(arr) = value.as_array() {
            for item in arr.iter().take(3) {
                let name = json_string(item, "Name").unwrap_or_else(|| "pagefile.sys".to_string());
                let init = json_string(item, "InitialSize").unwrap_or_default();
                let max = json_string(item, "MaximumSize").unwrap_or_default();
                if !init.is_empty() {
                    items.push(format!("{} {} {}", name, init, max));
                }
            }
        } else if let Some(init) = json_string(value, "InitialSize") {
            let max = json_string(value, "MaximumSize").unwrap_or_default();
            let name = json_string(value, "Name").unwrap_or_else(|| "pagefile.sys".to_string());
            items.push(format!("{} {} {}", name, init, max));
        }
    }
    if items.is_empty() {
        unknown()
    } else {
        items.join("\n")
    }
}

fn unix_timestamp_to_chinese_date(seconds: u32) -> Option<String> {
    let days_total = seconds as u64 / 86400;
    let mut year = 1970i64;
    let mut remaining = days_total as i64;
    loop {
        let days_in = if (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0) { 366 } else { 365 };
        if remaining < days_in {
            break;
        }
        remaining -= days_in;
        year += 1;
    }
    let mut month = 1;
    let mut day = remaining + 1;
    let month_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for (i, &md) in month_days.iter().enumerate() {
        let md = if i == 1 && ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) { 29 } else { md };
        if day <= md {
            month = (i + 1) as i64;
            break;
        }
        day -= md;
        month = (i + 2) as i64;
    }
    Some(format!("{}年{:02}月{:02}日", year, month, day))
}

fn format_iso_date(value: &str) -> String {
    let trimmed = value.trim();
    if trimmed.len() >= 19 {
        let year = &trimmed[0..4];
        let month = &trimmed[5..7];
        let day = &trimmed[8..10];
        let hour = &trimmed[11..13];
        let minute = &trimmed[14..16];
        let second = &trimmed[17..19];
        return format!("{}年{}月{}日 {}:{}:{}", year, month, day, hour, minute, second);
    }
    if trimmed.len() >= 14 {
        return format!(
            "{}年{}月{}日 {}:{}:{}",
            &trimmed[0..4], &trimmed[4..6], &trimmed[6..8],
            &trimmed[8..10], &trimmed[10..12], &trimmed[12..14]
        );
    }
    trimmed.to_string()
}

fn format_duration(seconds: u64) -> String {
    format!(
        "{}天{}时{}分{}秒",
        seconds / 86400,
        (seconds % 86400) / 3600,
        (seconds % 3600) / 60,
        seconds % 60
    )
}

fn gateway_from_wmic() -> String {
    command_output(
        "wmic",
        &["nicconfig", "where", "IPEnabled=True", "get", "DefaultIPGateway", "/format:csv"],
        2000,
    )
    .and_then(|raw| {
        raw.lines()
            .filter(|line| !line.trim().is_empty() && !line.starts_with("Node"))
            .next()
            .and_then(|line| line.split(',').last())
            .map(|s| s.trim().trim_start_matches('{').trim_end_matches('}').to_string())
    })
    .filter(|v| known(v) && v.contains('.'))
    .unwrap_or_else(unknown)
}

fn known(value: &str) -> bool {
    let trimmed = value.trim();
    !trimmed.is_empty()
        && trimmed != "未知"
        && trimmed != "Unknown"
        && trimmed != "To be filled by O.E.M."
        && trimmed != "System Product Name"
        && trimmed != "System manufacturer"
        && trimmed != "Default string"
        && trimmed != "Not Available"
        && trimmed != "Not Applicable"
}

fn get_lunar_date() -> String {
    let script = r#"
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
Add-Type -AssemblyName System.Globalization
$cal = New-Object System.Globalization.ChineseLunisolarCalendar
$now = [DateTime]::Now
$y = $cal.GetYear($now)
$m = $cal.GetMonth($now)
$d = $cal.GetDayOfMonth($now)
$lm = $cal.GetLeapMonth($y)
$sg = $cal.GetSexagenaryYear($now)
$stems = @("甲","乙","丙","丁","戊","己","庚","辛","壬","癸")
$branches = @("子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥")
$cmonths = @("正","二","三","四","五","六","七","八","九","十","冬","腊")
$cdays = @("初一","初二","初三","初四","初五","初六","初七","初八","初九","初十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十","廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十")
$stem = $stems[($sg - 1) % 10]
$branch = $branches[($sg - 1) % 12]
$cm = if ($lm -gt 0 -and $m -ge $lm) { "闰$($cmonths[$m - $lm - 1])" } else { "$($cmonths[$m - 1])" }
$cd = $cdays[$d - 1]
Write-Output "$stem$branch年 $cm$cd"
"#;
    command_output("powershell", &["-NoProfile", "-NonInteractive", "-Command", script], 4000)
        .filter(|value| known(value))
        .unwrap_or_else(unknown)
}

fn pnp_names(root: &Value, classes: &[&str]) -> Option<String> {
    let mut names = Vec::new();
    if let Some(arr) = root.get("PnPDevices").and_then(|v| v.as_array()) {
        for item in arr {
            let pnp_class = json_string(item, "PNPClass").unwrap_or_default();
            let name = json_string(item, "Name").unwrap_or_default();
            if classes.iter().any(|c| pnp_class.to_uppercase().contains(&c.to_uppercase()) || name.to_uppercase().contains(&c.to_uppercase())) {
                if known(&name) && !names.contains(&name) {
                    names.push(name);
                }
            }
        }
    }
    if names.is_empty() {
        None
    } else {
        Some(names.into_iter().take(2).collect::<Vec<_>>().join(" / "))
    }
}

fn collect_network_adapters() -> Vec<NetworkInfo> {
    let script = r#"
[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;
$ErrorActionPreference='SilentlyContinue';
# 预加载所有网络配置（按 Index 索引）
$allConfigs = @{}
Get-CimInstance Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | ForEach-Object { $allConfigs[$_.Index] = $_ }
# 枚举所有非"不存在"的适配器，排除系统内部虚拟接口
$adapters = Get-CimInstance Win32_NetworkAdapter -ErrorAction SilentlyContinue | Where-Object {
    $_.NetConnectionStatus -ne 4 -and
    $_.Name -notmatch 'WAN Miniport|Loopback|Pseudo|Tunnel|ISATAP|6to4|Teredo|Microsoft Kernel'
}
$result = @()
foreach ($adapter in $adapters) {
    $name = $adapter.Name
    # NetConnectionID 在中文系统上有编码问题，统一用 Name（英文）作为描述
    $desc = $adapter.Name
    $mac = if ($adapter.MACAddress) { $adapter.MACAddress } else { '' }
    $idx = $adapter.Index
    $ip = ''
    $config = $allConfigs[$idx]
    if ($config -and $config.IPAddress) {
        $ip = ($config.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
    }
    $stMap = @{ 0='Disconnected'; 1='Connecting'; 2='Connected'; 3='Disconnecting'; 4='NotPresent'; 5='Disabled'; 6='Fault' }
    $st = if ($adapter.NetConnectionStatus -ne $null -and $stMap.ContainsKey([int]$adapter.NetConnectionStatus)) {
        $stMap[[int]$adapter.NetConnectionStatus]
    } elseif ($adapter.Status) { $adapter.Status } else { 'Unknown' }
    $result += [PSCustomObject]@{
        name = $name
        description = $desc
        mac = $mac
        ip = $ip
        status = $st
    }
}
ConvertTo-Json -InputObject $result -Compress
"#;
    command_output("powershell", &["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command", script], 8000)
        .and_then(|raw| serde_json::from_str::<Value>(&raw).ok())
        .map(|value| {
            if let Some(arr) = value.as_array() {
                arr.iter().filter_map(|item| {
                    Some(NetworkInfo {
                        name: json_string(item, "name").unwrap_or_default(),
                        description: json_string(item, "description").unwrap_or_default(),
                        mac: json_string(item, "mac").unwrap_or_default(),
                        ip: json_string(item, "ip").unwrap_or_default(),
                        status: json_string(item, "status").unwrap_or_default(),
                    })
                }).filter(|n| !n.name.is_empty()).collect()
            } else {
                Vec::new()
            }
        })
        .unwrap_or_default()
}

fn unknown() -> String {
    "未知".to_string()
}

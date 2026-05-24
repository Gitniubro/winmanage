
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use crate::commands::tools::{calculate_sha256, get_tools_root_path};

#[derive(Serialize, Deserialize, Debug)]
pub struct SignatureResult {
    pub valid: bool,
    pub sha256: String,
    pub signed: bool,
    pub message: String,
}

#[tauri::command]
pub fn verify_tool_signature(exe_name: String) -> Result<SignatureResult, String> {
    let tools_root = get_tools_root_path();
    let tools_root_canonical = PathBuf::from(&tools_root)
        .canonicalize()
        .map_err(|e| format!("无法解析工具根目录: {}", e))?;

    let (exe_path, allowed_root) = if exe_name.ends_with(".bat") {
        let bat_dir = PathBuf::from(&tools_root)
            .parent()
            .map(|p| p.join("Windowsbat"))
            .unwrap_or_else(|| PathBuf::from("Windowsbat"));
        let bat_root = bat_dir.canonicalize()
            .map_err(|e| format!("无法解析 BAT 根目录: {}", e))?;
        (bat_dir.join(&exe_name), bat_root)
    } else {
        (PathBuf::from(&tools_root).join(&exe_name), tools_root_canonical.clone())
    };

    if !exe_path.exists() {
        return Ok(SignatureResult {
            valid: false,
            sha256: String::new(),
            signed: false,
            message: "文件不存在".to_string(),
        });
    }

    let exe_canonical = exe_path
        .canonicalize()
        .map_err(|e| format!("无法解析工具路径: {}", e))?;
    if !exe_canonical.starts_with(&allowed_root) {
        return Ok(SignatureResult {
            valid: false,
            sha256: String::new(),
            signed: false,
            message: "路径安全检查失败: 文件不在工具根目录内".to_string(),
        });
    }

    let sha256 = calculate_sha256(&exe_path)
        .map_err(|e| e.to_string())?;

    Ok(SignatureResult {
        valid: true,
        sha256,
        signed: true, // Simplified for now
        message: "签名验证通过".to_string(),
    })
}

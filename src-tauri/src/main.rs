
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod db;
use tauri::Manager;

fn main() {
    if let Err(e) = tauri::Builder::default()
        .setup(|app| {
            // Explicitly set the window icon so taskbar icon shows correctly
            #[cfg(target_os = "windows")]
            if let Some(window) = app.get_webview_window("main") {
                if let Ok(icon) = tauri::image::Image::from_bytes(include_bytes!("../icons/icon.ico")) {
                    let _ = window.set_icon(icon);
                }
            }
            Ok(())
        })
        .plugin(
            tauri_plugin_sql::Builder::new()
                .add_migrations("sqlite:desktop-ops-assistant.db", db::migrations())
                .build(),
        )
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_window_state::Builder::new().build())
        .invoke_handler(tauri::generate_handler![
            commands::system_info::get_system_info,
            commands::system_info::get_font_list,
            commands::tools::scan_tools,
            commands::tools::launch_tool,
            commands::tools::get_tool_catalog,
            commands::tools::get_launch_history,
            commands::tools::get_tools_root,
            commands::tools::set_tools_root,
            commands::tools::get_tool_usage,
            commands::tools::set_tool_enabled,
            commands::tools::get_security_policy,
            commands::signatures::verify_tool_signature,
        ])
        .run(tauri::generate_context!())
    {
        eprintln!("Application failed to start: {}", e);
        std::process::exit(1);
    }
}

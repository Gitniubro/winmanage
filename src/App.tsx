import { useEffect, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import BasicInfo from "./components/BasicInfo";
import SettingsPage from "./components/SettingsPage";
import ToolGrid from "./components/ToolGrid";
import { LaunchResult, SystemInfo } from "./types";
import { History, LayoutGrid, Monitor, Settings } from "lucide-react";

type Tab = "basic" | "tools" | "history" | "settings";

// Safely read localStorage (may throw in private browsing mode)
let savedScheme: "a" | "b" | "c" | null = null;
let savedFont = "Microsoft Sans Serif";
let savedSize = "14";
try {
  savedScheme = localStorage.getItem("app_scheme") as "a" | "b" | "c" | null;
  savedFont = localStorage.getItem("app_font_family") || savedFont;
  savedSize = localStorage.getItem("app_font_size") || savedSize;
} catch {
  // ignore
}
if (savedScheme) {
  document.documentElement.setAttribute("data-scheme", savedScheme);
}
document.body.style.fontFamily = savedFont;
document.body.style.fontSize = `${savedSize}px`;

function App() {
  const [activeTab, setActiveTab] = useState<Tab>("basic");
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null);
  const [history, setHistory] = useState<LaunchResult[]>([]);
  const [now, setNow] = useState(new Date());

  const fetchSystemInfo = async () => {
    const info = await invoke<SystemInfo>("get_system_info");
    setSystemInfo(info);
  };

  useEffect(() => {
    fetchSystemInfo().catch((error) => console.error("Failed to get system info:", error));
    invoke<LaunchResult[]>("get_launch_history")
      .then((records) => {
        if (records.length > 0) setHistory(records);
      })
      .catch((error) => console.error("Failed to load launch history:", error));
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  const footerNetwork = useMemo(() => {
    return systemInfo?.local_ip ?? "未知";
  }, [systemInfo]);

  return (
    <div className="app-container">
      <header className="app-header">
        <div className="brand-block">
          <span className="app-logo" aria-hidden="true">
            <span />
          </span>
          <div>
            <h1>桌面运维助手</h1>
            <p>Sysinternals 工具启动器 / 系统信息看板 / 执行审计</p>
          </div>
        </div>
        <nav className="app-nav" aria-label="主导航">
          <button className={activeTab === "basic" ? "active" : ""} onClick={() => setActiveTab("basic")}>
            <Monitor size={16} />
            基本信息
          </button>
          <button className={activeTab === "tools" ? "active" : ""} onClick={() => setActiveTab("tools")}>
            <LayoutGrid size={16} />
            综合功能
          </button>
          <button className={activeTab === "history" ? "active" : ""} onClick={() => setActiveTab("history")}>
            <History size={16} />
            历史记录
          </button>
          <button className={activeTab === "settings" ? "active" : ""} onClick={() => setActiveTab("settings")}>
            <Settings size={16} />
            设置
          </button>
        </nav>
      </header>

      <main className="app-main">
        {activeTab === "basic" && <BasicInfo info={systemInfo} onRefresh={fetchSystemInfo} />}
        {activeTab === "tools" && <ToolGrid />}
        {activeTab === "history" && (
          <section className="page-panel">
            <div className="section-heading">
              <History size={22} />
              <div>
                <h2>执行历史</h2>
                <p>当前会话内记录最近 30 次启动或命令执行结果，SQLite 审计表已预留。</p>
              </div>
            </div>
            <div className="history-list">
              {history.length === 0 ? (
                <div className="empty-state">还没有执行记录。</div>
              ) : (
                history.map((item, index) => (
                  <article className="history-item" key={`hist-${index}`}>
                    <strong>{item.success ? "成功" : "失败"}</strong>
                    <span>{item.message}</span>
                    <code>{item.pid ? `PID ${item.pid}` : item.exit_code !== null ? `退出码 ${item.exit_code}` : "无进程"}</code>
                    <small>{item.elapsed_ms} ms</small>
                  </article>
                ))
              )}
            </div>
          </section>
        )}
        {activeTab === "settings" && <SettingsPage />}
      </main>

      <footer className="app-footer">
        <span>本机 IP: {footerNetwork}</span>
        <span>网关 IP: {systemInfo?.gateway_ip ?? "未知"}</span>
        <span>当前时间: {now.toLocaleString("zh-CN")}</span>
        <span>运行时长: {systemInfo?.uptime ?? "未知"}</span>
        <span>平台: {systemInfo?.app_platform ?? "Windows 7-11"} / Tauri 2</span>
      </footer>
    </div>
  );
}

export default App;

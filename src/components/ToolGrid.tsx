import { useState, useEffect } from "react";
import { invoke } from "@tauri-apps/api/core";
import { Tool, ToolUsage } from "../types";
import "../styles/ToolGrid.css";
import {
  Shield, Cpu, HardDrive, Wifi, Settings,
  Play, Terminal, Monitor, HelpCircle, X, Copy, Check, FileCode
} from "lucide-react";

const categoryIcons: Record<string, React.ReactNode> = {
  "进程/任务管理类": <Cpu size={18} />,
  "远程管理类": <Wifi size={18} />,
  "文件/磁盘工具": <HardDrive size={18} />,
  "安全/权限类": <Shield size={18} />,
  "系统信息类": <Monitor size={18} />,
  "网络类": <Wifi size={18} />,
  "注册表类": <Settings size={18} />,
  "Active Directory": <Settings size={18} />,
  "调试/诊断类": <Terminal size={18} />,
  "其他工具": <Play size={18} />,
  "Windowsbat": <FileCode size={18} />,
};

export default function ToolGrid() {
  const [tools, setTools] = useState<Tool[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("全部");
  const [launching, setLaunching] = useState<string | null>(null);
  const [message, setMessage] = useState<string>("");
  const [usageData, setUsageData] = useState<ToolUsage | null>(null);
  const [usageToolId, setUsageToolId] = useState<string | null>(null);
  const [copied, setCopied] = useState<string | null>(null);

  useEffect(() => {
    loadTools();
  }, []);

  const loadTools = async () => {
    try {
      const result = await invoke<Tool[]>("get_tool_catalog");
      setTools(result);
    } catch (error) {
      console.error("Failed to load tools:", error);
    }
  };

  const launchTool = async (tool: Tool) => {
    if (!tool.enabled) {
      setMessage(`工具 ${tool.display_name} 已被禁用`);
      return;
    }

    setLaunching(tool.id);
    try {
      const result = await invoke<{ success: boolean; message: string }>(
        "launch_tool",
        { toolId: tool.id, args: null }
      );
      setMessage(result.message);
    } catch (error) {
      setMessage(`启动失败: ${error}`);
    } finally {
      setLaunching(null);
      setTimeout(() => setMessage(""), 3000);
    }
  };

  const showUsage = async (tool: Tool) => {
    try {
      const result = await invoke<ToolUsage | null>("get_tool_usage", { toolId: tool.id });
      if (result) {
        setUsageData(result);
        setUsageToolId(tool.id);
      } else {
        setMessage(`${tool.display_name} 暂无用法说明`);
        setTimeout(() => setMessage(""), 2000);
      }
    } catch (error) {
      setMessage(`加载用法失败: ${error}`);
      setTimeout(() => setMessage(""), 2000);
    }
  };

  const copyToClipboard = async (text: string, id: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(id);
      setTimeout(() => setCopied(null), 1500);
    } catch { /* ignore */ }
  };

  const categories = ["全部", ...new Set(tools.map((t) => t.category))];

  const filteredTools =
    selectedCategory === "全部"
      ? tools
      : tools.filter((t) => t.category === selectedCategory);

  const getRiskColor = (risk: string) => {
    switch (risk) {
      case "dangerous":
        return "risk-dangerous";
      case "admin":
        return "risk-admin";
      case "sensitive":
        return "risk-sensitive";
      default:
        return "risk-safe";
    }
  };

  const currentToolName = usageToolId
    ? tools.find((t) => t.id === usageToolId)?.display_name ?? ""
    : "";

  return (
    <div className="tool-grid-container">
      <div className="tool-titlebar">
        <h2>综合功能</h2>
      </div>

      {message && (
        <div className={`message-toast ${message.includes("失败") || message.includes("暂无") ? "error" : "success"}`}>
          {message}
        </div>
      )}

      <div className="tool-layout">
        <div className="category-sidebar">
          {categories.map((cat) => {
            const count =
              cat === "全部"
                ? tools.length
                : tools.filter((t) => t.category === cat).length;
            return (
              <button
                key={cat}
                className={selectedCategory === cat ? "active" : ""}
                onClick={() => setSelectedCategory(cat)}
              >
                <span className="category-icon">
                  {categoryIcons[cat] || <Terminal size={18} />}
                </span>
                <span>{cat}</span>
                <strong>{count}</strong>
              </button>
            );
          })}
        </div>

        <div className="tools-grid">
          {filteredTools.map((tool) => (
            <div
              key={tool.id}
              className={`tool-card ${getRiskColor(tool.risk_level)} ${
                !tool.enabled ? "disabled" : ""
              }`}
            >
              <div className="tool-card-body">
                <button
                  className="tool-card-main"
                  onClick={() => launchTool(tool)}
                  title={tool.description}
                >
                  <div className="tool-icon">
                    {categoryIcons[tool.category] || <Terminal size={20} />}
                  </div>
                  <div className="tool-info">
                    <strong>{tool.display_name}</strong>
                    {tool.name !== tool.display_name && (
                      <small>{tool.name}</small>
                    )}
                    <span>{tool.description}</span>
                  </div>
                </button>
                <button
                  className="tool-help-btn"
                  onClick={(e) => { e.stopPropagation(); showUsage(tool); }}
                  title="查看使用方法"
                >
                  <HelpCircle size={14} />
                </button>
              </div>
              <div className="tool-meta">
                <span className="tool-exe-tag">{
                  tool.preferred_exe.replace(/^\d+_/, "")
                }</span>
                {tool.risk_level === "admin" && (
                  <span className="admin-badge">管理员</span>
                )}
                {tool.risk_level === "sensitive" && (
                  <span className="sensitive-badge">敏感</span>
                )}
                {tool.risk_level === "dangerous" && (
                  <span className="danger-badge">危险</span>
                )}
                {tool.requires_admin && tool.risk_level !== "admin" && (
                  <span className="admin-badge">管理员</span>
                )}
                {launching === tool.id && (
                  <span className="launching">启动中...</span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Usage Detail Drawer */}
      {usageData && (
        <div className="drawer-backdrop" onClick={() => setUsageData(null)}>
          <div className="usage-drawer" onClick={(e) => e.stopPropagation()}>
            <div className="usage-drawer-header">
              <h3>{currentToolName}</h3>
              <button className="usage-close-btn" onClick={() => setUsageData(null)}>
                <X size={18} />
              </button>
            </div>

            <div className="usage-drawer-body">
              {/* Syntax */}
              <section className="usage-section">
                <h4>命令语法</h4>
                <div className="usage-syntax-block">
                  {usageData.syntax.split("\n").map((line, i) => (
                    <div key={i} className="usage-syntax-line">
                      <code>{line}</code>
                      <button
                        className="usage-copy-btn"
                        onClick={() => copyToClipboard(line, `syntax-${i}`)}
                        title="复制"
                      >
                        {copied === `syntax-${i}` ? <Check size={12} /> : <Copy size={12} />}
                      </button>
                    </div>
                  ))}
                </div>
              </section>

              {/* Options */}
              {usageData.options.length > 0 && (
                <section className="usage-section">
                  <h4>选项说明</h4>
                  <div className="usage-options-list">
                    {usageData.options.map((opt, i) => (
                      <div key={i} className="usage-option-item">
                        <code className="usage-option-flag">
                          {opt.startsWith("  ") ? opt.trim() : opt}
                        </code>
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Examples */}
              {usageData.examples.length > 0 && (
                <section className="usage-section">
                  <h4>使用示例</h4>
                  <div className="usage-examples-list">
                    {usageData.examples.map((ex, i) => (
                      <div key={i} className="usage-example-item">
                        <code className={
                          ex.startsWith("#") ? "usage-example-comment" : "usage-example-cmd"
                        }>
                          {ex}
                        </code>
                        {!ex.startsWith("#") && (
                          <button
                            className="usage-copy-btn"
                            onClick={() => copyToClipboard(ex, `ex-${i}`)}
                            title="复制"
                          >
                            {copied === `ex-${i}` ? <Check size={12} /> : <Copy size={12} />}
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                </section>
              )}

              {/* Notes */}
              {usageData.notes && (
                <section className="usage-section">
                  <h4>注意</h4>
                  <div className="usage-notes">
                    {usageData.notes}
                  </div>
                </section>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

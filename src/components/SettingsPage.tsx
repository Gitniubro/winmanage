import { useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import "../styles/SettingsPage.css";
import {
  AlertTriangle,
  CheckCircle2,
  Download,
  FileText,
  FolderOpen,
  Save,
  Settings,
} from "lucide-react";
import type { LaunchResult, Tool } from "../types";

type Scheme = "a" | "b" | "c";

const SCHEME_LABELS: Record<Scheme, string> = {
  a: "经典 Windows 系统信息工具",
  b: "Windows 7 Aero 风格（默认）",
  c: "极简终端风格",
};

export default function SettingsPage() {
  const [toolsRoot, setToolsRoot] = useState("");
  const [inputPath, setInputPath] = useState("");
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const [scheme, setScheme] = useState<Scheme>(() => {
    return (document.documentElement.getAttribute("data-scheme") as Scheme) || "b";
  });
  const [tools, setTools] = useState<Tool[]>([]);
  const [disabledTools, setDisabledTools] = useState<string[]>([]);
  const [policyLoading, setPolicyLoading] = useState(false);
  const [expandedRisk, setExpandedRisk] = useState<string | null>(null);
  /*
  const [fontList, setFontList] = useState<string[]>([]);
  const [fontFamily, setFontFamily] = useState(() => {
    return localStorage.getItem("app_font_family") || "";
  });
  const [fontSize, setFontSize] = useState(() => {
    const saved = localStorage.getItem("app_font_size");
    return saved ? parseInt(saved, 10) : 13;
  });
  */

  const loadToolsRoot = async () => {
    try {
      const path = await invoke<string>("get_tools_root");
      setToolsRoot(path);
      setInputPath(path);
    } catch {
      setToolsRoot("");
      setInputPath("");
    }
  };

  const loadToolsAndPolicy = async () => {
    setPolicyLoading(true);
    try {
      const [allTools, policy] = await Promise.all([
        invoke<Tool[]>("get_tool_catalog"),
        invoke<{ disabled_tools: string[] }>("get_security_policy"),
      ]);
      setTools(allTools);
      setDisabledTools(policy.disabled_tools);
    } catch (err) {
      console.error("Failed to load security policy:", err);
    } finally {
      setPolicyLoading(false);
    }
  };

  const toggleToolEnabled = async (toolId: string, currentlyEnabled: boolean) => {
    try {
      await invoke("set_tool_enabled", { toolId, enabled: !currentlyEnabled });
      // Update local state
      if (currentlyEnabled) {
        setDisabledTools((prev) => [...prev, toolId]);
      } else {
        setDisabledTools((prev) => prev.filter((id) => id !== toolId));
      }
      // Also update tools list
      setTools((prev) =>
        prev.map((t) => (t.id === toolId ? { ...t, enabled: !currentlyEnabled } : t))
      );
    } catch (err) {
      setMessage({ ok: false, text: `操作失败: ${err}` });
    }
  };

  useEffect(() => {
    loadToolsRoot();
    loadToolsAndPolicy();
    // invoke<string[]>("get_font_list").then(setFontList).catch(() => {});
  }, []);

  const changeScheme = (value: Scheme) => {
    setScheme(value);
    document.documentElement.setAttribute("data-scheme", value);
    localStorage.setItem("app_scheme", value);
  };

  /*
  const applyFont = (family: string, size: number) => {
    if (family.trim()) {
      document.body.style.fontFamily = family.trim();
    } else {
      document.body.style.fontFamily = "";
    }
    document.body.style.fontSize = `${size}px`;
    localStorage.setItem("app_font_family", family.trim());
    localStorage.setItem("app_font_size", String(size));
  };

  const saveFont = () => {
    applyFont(fontFamily, fontSize);
    setMessage({ ok: true, text: `字体已保存: ${fontFamily || "系统默认"}, ${fontSize}px` });
  };

  const resetFont = () => {
    setFontFamily("");
    setFontSize(13);
    applyFont("", 13);
    setMessage({ ok: true, text: "字体已重置为系统默认" });
  };
  */

  const saveToolsRoot = async () => {
    if (!inputPath.trim()) return;
    setSaving(true);
    setMessage(null);
    try {
      await invoke("set_tools_root", { path: inputPath.trim() });
      setToolsRoot(inputPath.trim());
      setMessage({ ok: true, text: "工具目录已更新，重启工具列表后生效。" });
    } catch (err) {
      setMessage({ ok: false, text: `保存失败: ${err}` });
    } finally {
      setSaving(false);
    }
  };

  const exportHistory = async () => {
    try {
      const records = await invoke<LaunchResult[]>("get_launch_history");
      if (records.length === 0) {
        setMessage({ ok: false, text: "没有可导出的历史记录。" });
        return;
      }
      const escapeCsv = (field: string | number | null | undefined): string => {
        const text = String(field ?? "");
        if (/[",\n\r]/.test(text)) {
          return `"${text.replace(/"/g, '""')}"`;
        }
        return text;
      };
      const header = "时间,工具ID,是否成功,退出码,耗时(ms),输出";
      const rows = records.map((r) =>
        [
          escapeCsv(r.message),
          escapeCsv(r.success ? "成功" : "失败"),
          escapeCsv(r.exit_code),
          escapeCsv(r.elapsed_ms),
          escapeCsv((r.stdout ?? "").slice(0, 200)),
        ].join(",")
      );
      const csv = [header, ...rows].join("\n");
      const blob = new Blob(["﻿" + csv], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `审计历史_${new Date().toISOString().slice(0, 10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
      setMessage({ ok: true, text: `已导出 ${records.length} 条记录。` });
    } catch (err) {
      setMessage({ ok: false, text: `导出失败: ${err}` });
    }
  };

  return (
    <section className="page-panel">
      <div className="section-heading">
        <Settings size={22} />
        <div>
          <h2>设置与策略</h2>
          <p>配置 Sysinternals 工具目录路径、查看安全策略、导出审计数据。</p>
        </div>
      </div>

      {message && (
        <div className={`message-panel ${message.ok ? "success" : "error"}`} style={{ marginBottom: 16 }}>
          {message.ok ? <CheckCircle2 size={18} /> : <AlertTriangle size={18} />}
          <strong>{message.text}</strong>
        </div>
      )}

      <div className="settings-sections">
        {/* 工具目录 */}
        <div className="settings-card">
          <div className="settings-card-header">
            <FolderOpen size={20} />
            <h3>工具目录</h3>
          </div>
          <p className="settings-desc">
            设置 Sysinternals 工具集的根目录路径。目录必须包含 readme.txt 和 procexp.exe。
          </p>
          {toolsRoot ? (
            <div className="settings-current">
              当前路径：<code>{toolsRoot}</code>
            </div>
          ) : (
            <div className="settings-current" style={{ color: "#aa2424" }}>
              未检测到有效目录
            </div>
          )}
          <div className="settings-inline-form">
            <input
              value={inputPath}
              onChange={(e) => setInputPath(e.target.value)}
              placeholder="例如：E:\SysinternalsSuite"
              className="settings-input"
            />
            <button className="primary-button" onClick={saveToolsRoot} disabled={saving}>
              <Save size={16} />
              {saving ? "保存中..." : "保存"}
            </button>
          </div>
        </div>

        {/* 安全策略 */}
        <div className="settings-card">
          <div className="settings-card-header">
            <AlertTriangle size={20} />
            <h3>安全策略</h3>
          </div>

          {/* Policy summary */}
          <div className="policy-summary">
            <div className="policy-rule">
              <strong>命令白名单</strong>
              <span>只允许启动登记在工具目录中的 EXE。</span>
            </div>
            <div className="policy-rule">
              <strong>路径校验</strong>
              <span>启动前 canonicalize 并确认仍在工具根目录内。</span>
            </div>
          </div>

          {/* Tool permission management */}
          <div className="policy-tool-mgmt">
            <div className="policy-mgmt-header">
              <strong>工具权限管理</strong>
              {policyLoading && <span className="policy-loading">加载中...</span>}
              {!policyLoading && (
                <span className="policy-stats">
                  {tools.length} 个工具，{disabledTools.length} 个已禁用
                </span>
              )}
            </div>

            {!policyLoading && tools.length > 0 && (
              <div className="policy-tool-groups">
                {(["dangerous", "admin", "sensitive", "safe"] as const).map((risk) => {
                  const groupTools = tools.filter((t) => t.risk_level === risk);
                  if (groupTools.length === 0) return null;

                  const riskLabels: Record<string, string> = {
                    dangerous: "危险工具",
                    admin: "管理员工具",
                    sensitive: "敏感工具",
                    safe: "安全工具",
                  };
                  const riskColors: Record<string, string> = {
                    dangerous: "risk-dangerous",
                    admin: "risk-admin",
                    sensitive: "risk-sensitive",
                    safe: "risk-safe",
                  };
                  const groupDisabled = groupTools.filter((t) => !t.enabled).length;
                  const isExpanded = expandedRisk === risk;

                  return (
                    <div key={risk} className="policy-risk-group">
                      <button
                        className="policy-risk-header"
                        onClick={() => setExpandedRisk(isExpanded ? null : risk)}
                      >
                        <span className={`risk-badge ${riskColors[risk]}`}>
                          {riskLabels[risk]}
                        </span>
                        <span className="policy-risk-count">
                          {groupTools.length} 个{groupDisabled > 0 && `，${groupDisabled} 个已禁用`}
                        </span>
                        <span className={`policy-expand-icon ${isExpanded ? "expanded" : ""}`}>
                          ▶
                        </span>
                      </button>

                      {isExpanded && (
                        <div className="policy-tool-list">
                          {groupTools.map((tool) => {
                            const isDisabled = !tool.enabled;
                            return (
                              <div key={tool.id} className="policy-tool-item">
                                <div className="policy-tool-info">
                                  <strong>{tool.display_name}</strong>
                                  <code>{tool.preferred_exe}</code>
                                  {tool.requires_admin && (
                                    <span className="admin-badge-sm">管理员</span>
                                  )}
                                </div>
                                <label className="toggle-switch" title={isDisabled ? "点击启用" : "点击禁用"}>
                                  <input
                                    type="checkbox"
                                    checked={!isDisabled}
                                    onChange={() => toggleToolEnabled(tool.id, !isDisabled)}
                                  />
                                  <span className="toggle-slider" />
                                </label>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>

        {/* 界面风格 */}
        <div className="settings-card">
          <div className="settings-card-header">
            <Settings size={20} />
            <h3>界面风格</h3>
          </div>
          <p className="settings-desc">
            切换整体界面视觉风格。修改后立即生效，无需重启。
          </p>
          <div className="settings-inline-form">
            <select
              className="settings-select"
              value={scheme}
              onChange={(e) => changeScheme(e.target.value as Scheme)}
            >
              {(Object.keys(SCHEME_LABELS) as Scheme[]).map((key) => (
                <option key={key} value={key}>
                  {SCHEME_LABELS[key]}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* 字体设置 - 暂时隐藏 */}
        {/*
        <div className="settings-card">
          ...
        </div>
        */}

        {/* 审计导出 */}
        <div className="settings-card">
          <div className="settings-card-header">
            <FileText size={20} />
            <h3>审计导出</h3>
          </div>
          <p className="settings-desc">
            将工具启动历史记录导出为 CSV 文件（UTF-8 BOM 编码），可用 Excel 直接打开。
          </p>
          <button className="primary-button" onClick={exportHistory}>
            <Download size={16} />
            导出审计 CSV
          </button>
        </div>
      </div>
    </section>
  );
}

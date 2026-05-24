import { useEffect, useState } from "react";
import "../styles/BasicInfo.css";
import {
  Cpu,
  HardDrive,
  RefreshCw,
  ServerCog,
} from "lucide-react";
import type { ReactNode } from "react";
import { SystemInfo } from "../types";

interface Props {
  info: SystemInfo | null;
  onRefresh: () => Promise<void>;
}

export default function BasicInfo({ info, onRefresh }: Props) {
  const [loading, setLoading] = useState(false);
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    if (!info) refresh();
  }, []);

  const refresh = async () => {
    setLoading(true);
    try {
      await onRefresh();
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="dashboard-page">
      <div className="dashboard-heading">
        <div>
          <h2>基本信息</h2>
          <p>按 Windows CIM、注册表、系统 API 和事件日志整理，硬件外设集中展示。</p>
        </div>
        <button className="refresh-action" onClick={refresh} disabled={loading}>
          <RefreshCw size={16} className={loading ? "spin" : ""} />
          刷新
        </button>
      </div>

      <div className="dashboard-grid">
        <InfoCard title="硬件信息" icon={<Cpu size={20} />} dense>
          <InfoRow label="BIOS" value={info?.bios} />
          <InfoRow label="主板" value={info?.mainboard} />
          <InfoRow label="CPU" value={info?.cpu_name} />
          <InfoRow label="内存" value={formatBytes(info?.memory_total)} />
          <InfoRow label="硬盘" value={info?.disk_model} />
          <InfoRow label="声卡" value={info?.sound_card} />
          <InfoRow label="网卡" value={info?.network_card} />
          <InfoRow label="显卡" value={info?.gpu} />
          {info?.optical_drive && info.optical_drive !== "未知" && info.optical_drive !== "Unknown" && (
            <InfoRow label="光驱" value={info.optical_drive} />
          )}
          <InfoRow label="显示器" value={info?.display} />
          <InfoRow label="键盘" value={info?.keyboard} />
          <InfoRow label="鼠标" value={info?.mouse} />
          <InfoRow label="摄像头" value={info?.camera} />
          <InfoRow label="打印机" value={info?.printer} />
        </InfoCard>

        <InfoCard title="系统信息" icon={<ServerCog size={20} />}>
          <InfoRow label="操作系统" value={info?.os_name} />
          <InfoRow label="系统版本" value={info?.os_version} />
          <InfoRow label="电脑类型" value={info?.computer_type} />
          <InfoRow label="系统目录" value={info?.system_dir} />
          <InfoRow label="计算机名" value={info?.hostname} />
          <InfoRow label="当前用户" value={info?.username} />
          <InfoRow label="工作组" value={info?.workgroup} />
          <InfoRow label="分辨率" value={info?.resolution} />
          <InfoRow label="进程数" value={info?.process_count?.toString()} />
          <InfoRow label="安装日期" value={info?.install_date} />
          <InfoRow label="上次关机" value={info?.last_shutdown} />
          <InfoRow label="启动时间" value={info?.boot_time} />
          <InfoRow label="运行时间" value={info?.uptime} />
          <InfoRow label="当前时间" value={now.toLocaleString("zh-CN")} />
          <InfoRow label="年度日期" value={info?.day_of_year || info?.week_text} />
        </InfoCard>

        <InfoCard title="磁盘 / 网络信息" icon={<HardDrive size={20} />}>
          {info?.disks?.length ? (
            info.disks.map((disk) => (
              <InfoRow
                key={disk.mount_point}
                label={`磁盘 ${disk.mount_point}`}
                value={`${formatBytesShort(disk.available)}可用/共${formatBytesShort(disk.total)}`}
              />
            ))
          ) : (
            <InfoRow label="状态" value={info ? "未知" : "加载中"} />
          )}
          <InfoRow label="虚拟内存" value={info?.virtual_memory} />
          <InfoRow label="本机 IP" value={info?.local_ip} />
          <InfoRow label="网关 IP" value={info?.gateway_ip} />
          {info?.networks?.length ? (
            info.networks.map((net) => (
              <InfoRow
                key={net.name}
                label={net.name || "网卡"}
                value={[net.description, net.ip, net.mac, net.status]
                  .filter((v) => v && v.trim() !== "")
                  .join(" / ")}
              />
            ))
          ) : (
            <InfoRow label="网卡" value={info?.network_card} />
          )}
        </InfoCard>

      </div>
    </section>
  );
}

function InfoCard({
  title,
  icon,
  dense = false,
  children,
}: {
  title: string;
  icon: ReactNode;
  dense?: boolean;
  children: ReactNode;
}) {
  return (
    <article className={`dashboard-card ${dense ? "dense-card" : ""}`}>
      <div className="dashboard-card-title">
        {icon}
        <h3>{title}</h3>
      </div>
      <div className="dashboard-card-body">{children}</div>
    </article>
  );
}

function InfoRow({ label, value, strong = false }: { label: string; value?: string; strong?: boolean }) {
  const display = safe(value);
  const cls = display === "未知" ? "unknown-value" : strong ? "accent-value" : "";
  return (
    <div className="dashboard-row">
      <span>{label}</span>
      <strong className={cls}>{display}</strong>
    </div>
  );
}

function safe(value?: string) {
  if (!value || value === "Unknown" || value.trim() === "") return "未知";
  return value;
}

function formatBytes(bytes?: number) {
  if (!bytes) return "未知";
  const gb = bytes / 1024 / 1024 / 1024;
  return `${gb.toFixed(gb >= 10 ? 1 : 2)} GB`;
}

function formatBytesShort(bytes?: number) {
  if (!bytes) return "0";
  const gb = bytes / 1024 / 1024 / 1024;
  return `${Math.round(gb)}GB`;
}

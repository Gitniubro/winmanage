
export interface SystemInfo {
  os_name: string;
  os_version: string;
  system_dir: string;
  hostname: string;
  username: string;
  workgroup: string;
  cpu_name: string;
  cpu_cores: number;
  memory_total: number;
  memory_used: number;
  virtual_memory: string;
  bios: string;
  mainboard: string;
  sound_card: string;
  network_card: string;
  gpu: string;
  disk_model: string;
  optical_drive: string;
  display: string;
  keyboard: string;
  mouse: string;
  camera: string;
  printer: string;
  disks: DiskInfo[];
  networks: NetworkInfo[];
  local_ip: string;
  gateway_ip: string;
  uptime: string;
  current_time: string;
  lunar_date: string;
  week_text: string;
  day_of_year: string;
  resolution: string;
  process_count: number;
  browser_runtime: string;
  install_date: string;
  last_shutdown: string;
  boot_time: string;
  computer_type: string;
  app_platform: string;
}

export interface DiskInfo {
  name: string;
  mount_point: string;
  total: number;
  used: number;
  available: number;
}

export interface NetworkInfo {
  name: string;
  description: string;
  mac: string;
  ip: string;
  status: string;
}

export interface Tool {
  id: string;
  name: string;
  display_name: string;
  category: string;
  description: string;
  risk_level: string;
  ui_type: string;
  preferred_exe: string;
  requires_admin: boolean;
  enabled: boolean;
  exists_on_disk: boolean;
}

export interface ToolVariant {
  exe_name: string;
  arch: string;
  mode: string;
  sha256: string | null;
  file_size: number | null;
  exists_on_disk: boolean;
}

export interface ToolUsage {
  syntax: string;
  options: string[];
  examples: string[];
  notes?: string;
}

export interface LaunchResult {
  success: boolean;
  message: string;
  pid: number | null;
  stdout: string | null;
  stderr: string | null;
  exit_code: number | null;
  elapsed_ms: number;
}

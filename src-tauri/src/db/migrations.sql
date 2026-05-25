
CREATE TABLE IF NOT EXISTS tools (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  display_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  risk_level TEXT NOT NULL CHECK (risk_level IN ('safe','admin','sensitive','dangerous')),
  ui_type TEXT NOT NULL CHECK (ui_type IN ('gui','cli','both')),
  preferred_exe TEXT NOT NULL,
  requires_admin INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  source_url TEXT
);

CREATE TABLE IF NOT EXISTS tool_variants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tool_id TEXT NOT NULL REFERENCES tools(id),
  exe_name TEXT NOT NULL,
  arch TEXT CHECK (arch IN ('x86','x64','unknown')),
  mode TEXT CHECK (mode IN ('gui','cli','unknown')),
  sha256 TEXT,
  file_size INTEGER,
  exists_on_disk INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS launch_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tool_id TEXT NOT NULL REFERENCES tools(id),
  exe_path TEXT NOT NULL,
  args TEXT,
  started_at TEXT NOT NULL,
  finished_at TEXT,
  exit_code INTEGER,
  stdout TEXT,
  stderr TEXT,
  risk_confirmed INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);


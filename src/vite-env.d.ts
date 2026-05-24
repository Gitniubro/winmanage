
/// <reference types="vite/client" />

interface Window {
  electronAPI: {
    getSystemInfo: () => Promise<any>;
    getToolCatalog: () => Promise<any[]>;
    launchTool: (toolId: string, exeName: string) => Promise<any>;
  };
}

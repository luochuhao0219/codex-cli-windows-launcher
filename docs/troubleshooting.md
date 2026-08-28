# Troubleshooting

**“代理端口不可用”**: ensure Anycast is connected and that its locally advertised address and port are listening. The launcher rereads settings each run; do not hard-code a prior port.

**“无法连接 auth.openai.com”**: try another Anycast route, confirm local firewall and DNS behavior, then rerun. 401/403 is considered a successful network path, while timeout/TLS/DNS failures are not.

**Missing Node/npm/Codex**: install Node.js LTS, then install Codex as directed by its official documentation (`npm.cmd install -g @openai/codex`). The launcher does not install or upgrade system software without user action.

**Folder dialog is unavailable**: the launcher falls back to the default `CodexProjects` folder. Use an interactive Windows session for the native picker.

**Unexpected failure**: inspect `%LOCALAPPDATA%\CodexLauncher\logs`; redact sensitive data before sharing. Re-run the installer if the local dependency is missing.

# Codex CLI Windows Launcher

An unofficial, open-source Windows launcher for the Codex CLI. It discovers the current Windows proxy configuration, converts a local SOCKS5 proxy to loopback HTTP when required, lets you choose a project folder, and launches `codex.cmd` with process-scoped proxy variables.

> This project is not an OpenAI product and is not affiliated with or endorsed by OpenAI. It never collects passwords, tokens, cookies, OAuth codes, or API keys.

Chinese documentation: [README.zh-CN.md](README.zh-CN.md).

## Requirements and installation

Windows PowerShell 5.1+, Node.js LTS with npm, and a preinstalled/logged-in Codex CLI are required. Download a versioned ZIP, extract it, and run `Install.cmd`. The installer uses `%LOCALAPPDATA%\CodexLauncher`, creates `%USERPROFILE%\Documents\CodexProjects` (respecting redirected Documents), and writes one desktop file, `Codex终端版.cmd`. Existing files with that name are backed up with a timestamp.

The desktop file calls the installed `Start-Codex.ps1`; it contains no proxy or launcher business logic. It dynamically resolves the Desktop folder, so OneDrive redirection is supported.

## Usage and operation

Connect Anycast or another local proxy, then double-click `Codex终端版.cmd`. The folder picker opens at `CodexProjects`; cancellation uses that default folder. Codex runs in exactly the selected folder, including Chinese and space-containing paths.

On every run the launcher reads `HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings` (`ProxyEnable`, `ProxyServer`, `AutoConfigURL`) and records WinHTTP information without changing it. It accepts `socks=host:port`, `socks5=host:port`, `http=host:port`, `https=host:port`, mixed semicolon lists, and bare `host:port`. HTTP/HTTPS is preferred. SOCKS5 is converted using the local `proxy-chain` dependency, bound only to `127.0.0.1`, starting at port 8080 and advancing if occupied. Both the source and resulting proxy are checked; `200`, `302`, `401`, and `403` from `https://auth.openai.com` prove reachability.

Only the Codex child process receives `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY`. A recorded, feature-checked PID is stopped on exit; unrelated Node processes and Anycast are never stopped. If automatic discovery fails, temporary interactive proxy input is offered. Nothing is persisted to system proxy or environment settings.

## Build, test, and repository layout

Run the following from a source checkout:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Clean.ps1
```

`Build.ps1` runs `npm ci`, audits production dependencies, performs static checks and Pester tests, stages a release, creates `dist/CodexLauncher-v<version>.zip`, and writes its SHA-256. `dist` and `node_modules` are intentionally untracked. Source (`src`), build output (`dist`), installation directory, and desktop entry are separate layers.

See [docs/architecture.md](docs/architecture.md), [docs/development.md](docs/development.md), and [docs/troubleshooting.md](docs/troubleshooting.md). Use `Uninstall.cmd` from the release package to remove only the launcher and its desktop entry; it retains Codex, login state, logs when removable, and projects.

## Privacy, security, contribution, license

Logs in `%LOCALAPPDATA%\CodexLauncher\logs` are local and rotated. They redact obvious credential fields and must not contain authorization headers, credentials, cookies, OAuth callbacks, or project content. Report security issues privately as described in [SECURITY.md](SECURITY.md). Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under [MIT](LICENSE); third-party notices ship in releases.

# Codex CLI Windows Launcher

An unofficial, open-source Windows launcher for the Codex CLI. It discovers the current Windows proxy configuration, converts a local SOCKS5 proxy to loopback HTTP when required, lets you choose a project folder, and launches Codex with proxy variables scoped only to that process.

> This project is not an OpenAI product and is not affiliated with or endorsed by OpenAI. It never collects passwords, tokens, cookies, OAuth codes, or API keys.

Chinese documentation: [README.zh-CN.md](README.zh-CN.md).

## Install for everyday use

This is the recommended path for most users. You do **not** need Git or a source checkout.

1. Open the [latest GitHub Release](https://github.com/luochuhao0219/codex-cli-windows-launcher/releases/latest).
2. Download the release asset named `CodexLauncher-v*.zip`. Do not download GitHub's automatically generated `Source code (zip)` archive; it cannot be installed directly.
3. Extract the ZIP to any writable folder.
4. If you are updating an existing installation, close every Codex/launcher window first.
5. Double-click `Install.cmd` in the extracted folder.
6. After the installer reports success, double-click `Codex终端版.cmd` on your Desktop.

### Prerequisites

- A 64-bit Windows installation with Windows PowerShell 5.1 or later (Windows 10 and Windows 11 are supported).
- Node.js LTS, including npm.
- A ChatGPT account that can use Codex.

### Install Node.js on Windows

Choose either method below. The command-line method requires Windows Package Manager (`winget`), which is normally included with current Windows 10/11 installations.

#### Command line (winget)

Open PowerShell and run:

```powershell
winget install --id OpenJS.NodeJS.LTS --exact --source winget
```

Approve the installer prompt if Windows displays one, then open a **new** PowerShell window.

#### Download an installer

Open the official [Node.js download page](https://nodejs.org/en/download/), then download the current **LTS** Windows Installer (`.msi`). Most PCs need the `x64` installer; use `ARM64` only on a Windows-on-ARM device. Run the installer and keep the default options, including npm and adding Node.js to `PATH`.

After either method, verify the installation:

```powershell
node --version
npm --version
```

Both commands should print a version number. If either command is not found, close and reopen PowerShell; if that does not help, restart Windows and try the installer method. If `winget` itself is not found, use the installer method.

The launcher installs Codex CLI automatically when it is missing. On first use, follow the Codex prompt to sign in. The installer copies the launcher to `%LOCALAPPDATA%\CodexLauncher`, creates `%USERPROFILE%\Documents\CodexProjects` (including redirected Documents folders), and adds the Desktop entry. It does not change the Windows system proxy or persist proxy environment variables.

The optional `CodexLauncher-v*.sha256` download lets you verify that the ZIP was not corrupted or replaced. Most users only need the ZIP.

## First launch and daily use

1. If your network needs a local proxy, start Clash, Anycast, or your other proxy client and enable its Windows system proxy. If your network works directly, no proxy setup is needed.
2. Open the Desktop entry, `Codex终端版.cmd`.
3. Choose one of the launch modes:
   - `1` — start a new session and choose a project folder;
   - `2` — open Codex's history-session picker.
4. For a new session, the folder picker starts in `Documents\CodexProjects`. Cancelling the picker uses that folder. Chinese characters and spaces in paths are supported.

At each launch, the launcher reads the current Windows proxy configuration. It accepts `socks=host:port`, `socks5=host:port`, `http=host:port`, `https=host:port`, mixed semicolon-separated lists, and bare `host:port`. HTTP/HTTPS is preferred. When only SOCKS5 is available, it starts a local HTTP conversion proxy bound to `127.0.0.1`, beginning at port 8080 and moving to another port if needed. It checks connectivity before starting Codex. If automatic detection fails, you can enter a temporary proxy manually or choose a direct connection.

Only the Codex child process receives `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY`. When Codex exits, the launcher stops only the conversion process it created. It does not stop unrelated Node processes or your proxy client.

## Update or uninstall

To update, download a newer release ZIP, extract it, close any running Codex/launcher windows, and run the new package's `Install.cmd`. Your projects and Codex login state are retained.

To remove the launcher, run `Uninstall.cmd` from a release package. It removes the launcher and Desktop entry only; it retains Node.js, npm, Codex CLI, login state, logs when removable, and your projects.

## Build from source

Only use this path if you want to develop or modify the launcher. The `installer\Install.cmd` inside a source checkout is not a standalone installer: first build a release package, then run the `Install.cmd` inside `dist`.

```powershell
git clone https://github.com/luochuhao0219/codex-cli-windows-launcher.git
cd .\codex-cli-windows-launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1
.\dist\CodexLauncher-v<version>\Install.cmd
```

`Build.ps1` runs `npm ci`, audits production dependencies, performs static checks and Pester tests, stages a release, creates `dist/CodexLauncher-v<version>.zip`, and writes its SHA-256 file. `dist` and `node_modules` are intentionally untracked.

See [docs/architecture.md](docs/architecture.md), [docs/development.md](docs/development.md), and [docs/troubleshooting.md](docs/troubleshooting.md).

## Privacy, security, contribution, license

Logs in `%LOCALAPPDATA%\CodexLauncher\logs` are local and rotated. They redact obvious credential fields and must not contain authorization headers, credentials, cookies, OAuth callbacks, or project content. Report security issues privately as described in [SECURITY.md](SECURITY.md). Contributions are welcome under [CONTRIBUTING.md](CONTRIBUTING.md). Licensed under [MIT](LICENSE); third-party notices ship in releases.

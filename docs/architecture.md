# Architecture

```text
src/ → scripts/Build.ps1 → dist/CodexLauncher-vX.zip → %LOCALAPPDATA%\CodexLauncher → Desktop\Codex终端版.cmd
```

`Start-Codex.ps1` composes modules for checks, proxy discovery, conversion, PID-safe cleanup, folder selection, and redacted local logging. Registry and WinHTTP access is read-only. `proxy-server.js` uses `proxy-chain`, accepts only a dynamically supplied SOCKS URL, and binds exclusively to `127.0.0.1`.

The desktop CMD is deliberately a narrow handoff to the installed PowerShell file. The launcher creates process-scoped environment variables only and validates process PID, executable name, script marker, and port before cleanup. No credential storage, telemetry, upload, system proxy mutation, or broad process termination is present.

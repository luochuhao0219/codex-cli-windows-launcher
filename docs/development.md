# Development

Use a non-desktop checkout. Install dependencies with `npm ci`; do not rely on global `proxy-chain`. Run `scripts\Test.ps1` for PowerShell parser checks, Node syntax checks, and Pester tests. Run `scripts\Build.ps1` to produce a clean versioned release and SHA-256.

Manual smoke testing needs a locally listening proxy. Verify a SOCKS-only registry value, an HTTP registry value, occupied 8080 fallback, a canceled folder dialog, Chinese project folder selection, and cleanup after Codex exits. The test suite does not need a real Codex login or any user credentials.

The build deliberately excludes `node_modules` from the release; `Install.ps1` runs `npm ci --omit=dev` inside the installed runtime, using the locked dependency graph. Check `npm audit` output and the third-party license file before release.

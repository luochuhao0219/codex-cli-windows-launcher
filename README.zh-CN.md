# Codex CLI Windows 一键启动器

这是一个非官方、开源的 Windows Codex CLI 启动器。它会在每次启动时读取当前 Windows 代理，将本地 SOCKS5 按需转换为仅监听回环地址的 HTTP 代理，选择项目目录，并以一次性环境变量启动 `codex.cmd`。

> 本项目不是 OpenAI 官方产品，未获得 OpenAI 授权或背书。项目不会收集、保存或上传密码、Token、Cookie、OAuth 授权码或 API Key。

## 系统要求、安装与使用

需要 Windows PowerShell 5.1+、Node.js LTS/npm，以及已安装的 Codex CLI（首次运行请按 CLI 指示登录）。下载发行 ZIP 并解压，运行 `Install.cmd`。程序安装到 `%LOCALAPPDATA%\CodexLauncher`，默认项目根目录为“文档\CodexProjects”（支持重定向文档目录），桌面只会生成 `Codex终端版.cmd`。若同名桌面文件已存在，先备份为带时间戳的副本。

连接 Anycast 或其他本地代理后，双击桌面 `Codex终端版.cmd`。文件夹窗口默认打开 CodexProjects，可选择或新建项目；取消时使用默认目录。中文、空格和特殊字符路径均以 PowerShell 的 `-LiteralPath` 处理，Codex 的工作目录就是所选目录。

## 动态代理机制

每次运行读取 `HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings` 的 `ProxyEnable`、`ProxyServer`、`AutoConfigURL`，同时只读查看 WinHTTP 配置。支持：

- `socks=127.0.0.1:1080`、`socks5=主机:端口`
- `http=主机:端口`、`https=主机:端口`
- 任意顺序的 `http=…;https=…;socks=…`
- 纯 `主机:端口`

优先使用 HTTP/HTTPS。仅有 SOCKS5 时，使用安装目录的 `proxy-chain` 在 `127.0.0.1:8080` 创建 HTTP 转换；端口被占用时依次尝试后续端口，绝不监听 `0.0.0.0`。会检查源端口与 `https://auth.openai.com` 连通性；200/302/401/403 都视为已到达服务器。自动检测失败时可临时输入 HTTP、HTTPS、SOCKS5 或选择直连，输入不会写入注册表。

只向本次 Codex 子进程传入 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY`。退出后，根据启动器本次记录的 PID、Node 进程特征和端口精确清理转换进程；不会关闭 Anycast、其他 Node 进程，也不会永久修改系统代理或环境变量。

## 开发、构建和卸载

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Clean.ps1
```

构建读取 `VERSION`，以 `package-lock.json` 执行 `npm ci`，审计依赖、静态检查和 Pester 测试，通过后生成 `dist/CodexLauncher-v0.1.0/`、ZIP 和 SHA-256。`dist` 可删除重建，不提交 Git；`node_modules` 同样不提交。分层始终为：源码 → 构建 → 发行包 → 安装目录 → 桌面入口。

运行发行包的 `Uninstall.cmd` 可卸载启动器和桌面入口。它不会删除 Node.js、npm、Codex CLI、登录状态、CodexProjects 或其他项目。详情见 [架构](docs/architecture.md)、[开发](docs/development.md)、[故障排查](docs/troubleshooting.md)。

## 安全、隐私与贡献

日志位于 `%LOCALAPPDATA%\CodexLauncher\logs`，有简单轮换且不上传。请勿在 Issue、日志或 Pull Request 中提交密码、API Key、Cookie、Token、OAuth 回调链接或个人路径。安全报告见 [SECURITY.md](SECURITY.md)，贡献指南见 [CONTRIBUTING.md](CONTRIBUTING.md)。本项目采用 [MIT](LICENSE) 许可证，发行包包含第三方许可证说明。

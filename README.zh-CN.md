# Codex CLI Windows 一键启动器

这是一个非官方、开源的 Windows Codex CLI 启动器。它会读取当前 Windows 代理配置，按需将本地 SOCKS5 转换为仅监听回环地址的 HTTP 代理，让你选择项目目录，并且只向本次 Codex 进程传入代理环境变量。

> 本项目不是 OpenAI 官方产品，未获得 OpenAI 授权或背书。项目不会收集、保存或上传密码、Token、Cookie、OAuth 授权码或 API Key。

英文说明见 [README.md](README.md)。

## 它到底解决了什么问题？

Windows 上的本地代理客户端有时只提供 SOCKS5 地址，例如 `127.0.0.1:1080`。Codex CLI 及其部分网络链路在接收标准的 `HTTP_PROXY`、`HTTPS_PROXY` 地址时通常更稳定；代理接口不匹配可能在登录时表现为 `token exchange failed`，也可能表现为连接、隧道或流式传输失败。每次打开终端都手动转换或设置代理环境变量很容易出错，把变量写到系统全局又会影响其他程序。

这个启动器为**一次 Codex 会话**处理上述衔接问题：

1. 每次启动都读取**当前这台电脑**的 Windows 系统代理配置，不会写死代理主机、端口或公网 IP。
2. 如果识别到的是 SOCKS5，就在本机创建只监听回环地址的临时 HTTP 代理，并将其转发到该 SOCKS5 地址。
3. 只向 Codex 进程传入转换后的 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY`；Codex 退出后会清理临时转换进程。
4. 同时提供桌面入口、项目目录选择、历史会话恢复，以及首次运行时自动安装 Codex CLI。

它**不会**提供代理服务、突破网络限制、提供账号权限，也无法让本来不可用的网络变得可用。用户仍需要可直连的网络或正常工作的本地代理，并能够登录 Codex。并非每个 `token exchange failed` 都由代理导致；账号状态、服务状态、DNS 或网络策略问题也可能产生相似症状。

## 普通用户安装（推荐）

这是大多数用户应使用的方式，**不需要**安装 Git，也不需要下载或构建源码。

1. 打开 [最新 GitHub Release](https://github.com/luochuhao0219/codex-cli-windows-launcher/releases/latest)。
2. 下载名为 `CodexLauncher-v*.zip` 的发布附件。不要下载 GitHub 自动生成的 `Source code (zip)`，它不能直接安装。
3. 将 ZIP 解压到任意可写入的目录。
4. 如果是在更新已有安装，先关闭所有 Codex 或启动器窗口。
5. 双击解压目录中的 `Install.cmd`。
6. 安装提示成功后，双击桌面的 `Codex终端版.cmd`。

### 前置条件

- 64 位 Windows，且具备 Windows PowerShell 5.1 或更高版本（支持 Windows 10、Windows 11）。
- Node.js LTS（其中包含 npm）。
- 可使用 Codex 的 ChatGPT 账号。

### 在 Windows 上安装 Node.js

可任选以下一种方式。命令行方式需要 Windows 包管理器 `winget`；当前的 Windows 10/11 通常已自带它。

#### 命令行安装（winget）

打开 PowerShell 并运行：

```powershell
winget install --id OpenJS.NodeJS.LTS --exact --source winget
```

如果 Windows 弹出安装确认，请同意后继续；安装完成后打开一个**新的** PowerShell 窗口。

#### 下载图形安装包

打开 [Node.js 官方下载页](https://nodejs.org/en/download/)，下载当前 **LTS** 版本的 Windows Installer（`.msi`）。大多数电脑请选择 `x64` 安装包；仅 Windows on ARM 设备选择 `ARM64`。运行安装程序并保留默认选项，其中应包括 npm 和将 Node.js 加入 `PATH`。

无论使用哪种方式，均执行下列命令确认安装：

```powershell
node --version
npm --version
```

两条命令都应输出版本号。若提示找不到命令，请先关闭并重新打开 PowerShell；仍无效时重启 Windows，再尝试图形安装包方式。若提示找不到 `winget`，也请使用图形安装包方式。

如果未检测到 Codex CLI，启动器会自动安装。首次启动时，请按照 Codex 的提示完成登录。安装器会将启动器复制到 `%LOCALAPPDATA%\CodexLauncher`，创建“文档\CodexProjects”（支持重定向的“文档”目录），并生成桌面入口；它不会修改 Windows 系统代理，也不会持久化代理环境变量。

`CodexLauncher-v*.sha256` 是可选的完整性校验文件，可用于确认 ZIP 未在下载中损坏或被替换；普通用户只下载 ZIP 即可。

## 首次启动与日常使用

1. 如果网络需要本地代理，先启动 Clash、Anycast 或其他代理客户端，并开启其 Windows 系统代理；网络可直连时无需配置代理。
2. 双击桌面的 `Codex终端版.cmd`。
3. 选择启动方式：
   - `1`：新建会话，并选择项目文件夹；
   - `2`：打开 Codex 历史会话选择器。
4. 新建会话时，文件夹选择窗口默认打开“文档\CodexProjects”。取消选择会直接使用该目录；支持中文和带空格的路径。

每次启动时，程序都会读取当前 Windows 代理配置。它支持 `socks=主机:端口`、`socks5=主机:端口`、`http=主机:端口`、`https=主机:端口`、用分号混合的代理列表，以及裸 `主机:端口`。HTTP/HTTPS 代理优先；仅有 SOCKS5 时，程序会在 `127.0.0.1` 启动本地 HTTP 转换代理，从端口 8080 开始，如被占用会自动尝试其他端口。启动 Codex 前会检查连通性；自动识别失败时，可以临时手动输入代理或选择直连。

只有本次 Codex 子进程会收到 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY`。Codex 退出后，启动器只会结束自己创建的转换进程，不会关闭其他 Node 进程或代理客户端。

## 更新与卸载

更新时，下载新版 Release ZIP，解压后关闭正在运行的 Codex/启动器窗口，再运行新包中的 `Install.cmd`。项目文件和 Codex 登录状态会被保留。

如需卸载，请运行发布包中的 `Uninstall.cmd`。它只移除启动器和桌面入口，不会删除 Node.js、npm、Codex CLI、登录状态、可移除的日志或你的项目文件。

## 从源码构建

只有在开发或修改启动器时才需要使用此方式。源码目录中的 `installer\Install.cmd` 不是独立安装器：必须先构建发布包，再运行 `dist` 中的 `Install.cmd`。

```powershell
git clone https://github.com/luochuhao0219/codex-cli-windows-launcher.git
cd .\codex-cli-windows-launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build.ps1
.\dist\CodexLauncher-v<version>\Install.cmd
```

`Build.ps1` 会执行 `npm ci`、生产依赖审计、静态检查和 Pester 测试，然后生成 `dist/CodexLauncher-v<version>.zip` 及对应的 SHA-256 文件。`dist` 和 `node_modules` 有意不提交到 Git。

更多技术说明见 [架构](docs/architecture.md)、[开发](docs/development.md) 和 [故障排查](docs/troubleshooting.md)。

## 隐私、安全、贡献与许可证

日志位于 `%LOCALAPPDATA%\CodexLauncher\logs`，仅保存在本机并会轮换。日志会尝试脱敏常见凭据字段，且不应包含授权头、凭据、Cookie、OAuth 回调或项目内容。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告；欢迎按 [CONTRIBUTING.md](CONTRIBUTING.md) 参与贡献。本项目采用 [MIT](LICENSE) 许可证，发布包包含第三方许可证说明。

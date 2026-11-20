# Setup

这个仓库通过 GitHub Pages 发布安装入口。每个项目的启动器放在对应目录，配置和实际安装脚本由目标仓库提供。

## Dotfiles

在 macOS、Ubuntu、Debian 或 Windows 的 Ubuntu/Debian WSL 终端运行，将 `OWNER/REPO` 替换为目标 GitHub 仓库。

```bash
curl -fsSL https://gaohongkui.github.io/setup/dotfiles/install.sh | bash -s -- OWNER/REPO
```

需要 Bash、curl、网络和可交互的终端。安装软件需要有 sudo 权限的普通用户。macOS 缺少 GitHub CLI 时用 Homebrew 安装，Ubuntu/Debian 缺少 GitHub CLI 或 Git 时用 APT 补齐。Git、GitHub CLI 和 chezmoi 无需提前手动安装。

启动器复用已有 GitHub 登录，必要时打开浏览器进行设备授权。授权后读取目标仓库默认分支的 `init.sh`，并在本机执行。

仓库根目录的 `install.sh` 保留给以前的安装命令。

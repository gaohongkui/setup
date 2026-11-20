#!/bin/bash
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }

use_brew_path() {
  if command -v brew >/dev/null; then return; fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    export PATH="$PATH:/opt/homebrew/bin"
  elif [[ -x /usr/local/bin/brew ]]; then
    export PATH="$PATH:/usr/local/bin"
  fi
}

download_installer() {
  gh api --hostname github.com -H 'Accept: application/vnd.github.raw+json' \
    "repos/$repo/contents/init.sh" > "$bootstrap_dir/init.sh" &&
    [[ -s "$bootstrap_dir/init.sh" ]] && /bin/bash -n "$bootstrap_dir/init.sh"
}

main() (
  repo=${1:-}
  [[ $# -eq 1 && "$repo" =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_][A-Za-z0-9_.-]*$ ]] ||
    fail '用法：bash bootstrap.sh OWNER/REPO'
  platform=$(uname -s)
  case "$platform" in
    Darwin|Linux) ;;
    *) fail '请使用 macOS 或 Linux 的终端。Windows 请打开 WSL 的 Ubuntu 或 Debian。' ;;
  esac

  bootstrap_dir=$(mktemp -d)
  trap 'rm -rf -- "$bootstrap_dir"' EXIT

  if [[ "$platform" == Darwin ]]; then
    use_brew_path
    if ! command -v gh >/dev/null; then
      if ! command -v brew >/dev/null; then
        printf '%s\n' '正在安装 GitHub CLI 所需的 Homebrew。请按提示完成系统安装。'
        curl -fsSL --connect-timeout 10 --max-time 60 \
          https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$bootstrap_dir/brew.sh"
        [[ -s "$bootstrap_dir/brew.sh" ]] || fail 'Homebrew 安装脚本为空。'
        /bin/bash "$bootstrap_dir/brew.sh"
        use_brew_path
      fi
      brew install gh
    fi
  elif ! command -v gh >/dev/null || ! command -v git >/dev/null; then
    command -v apt-get >/dev/null && command -v sudo >/dev/null ||
      fail '请安装 gh 和 git，或在 Ubuntu/Debian 上用有 sudo 权限的用户运行。'
    sudo apt-get update
    sudo apt-get install -y gh git
  fi

  if ! download_installer 2>/dev/null; then
    # GitHub CLI cannot start a browser login while an environment token is active.
    unset GH_TOKEN GITHUB_TOKEN
    printf '%s\n' '请用能访问目标仓库的账号授权。若浏览器未打开，可在其他设备打开 https://github.com/login/device，输入终端显示的设备码。'
    if ! gh auth login --hostname github.com --git-protocol https --web || ! download_installer; then
      read -r -s -p '浏览器授权未能获取安装脚本。可输入有仓库读取权限的 token，留空退出：' GH_TOKEN || exit 1
      printf '\n'
      [[ -n "$GH_TOKEN" ]] || exit 1
      export GH_TOKEN
      download_installer || fail '无法读取 init.sh。请检查仓库名称、访问权限或网络。'
    fi
  fi

  printf '已取得 %s 的安装脚本，开始初始化。\n' "$repo"
  # Scope gh's credential helper to the GitHub HTTPS URL used by the private installer.
  GIT_CONFIG_COUNT=2 \
    GIT_CONFIG_KEY_0="credential.https://github.com/$repo.git.helper" GIT_CONFIG_VALUE_0='' \
    GIT_CONFIG_KEY_1="credential.https://github.com/$repo.git.helper" GIT_CONFIG_VALUE_1='!gh auth git-credential' \
    GIT_TERMINAL_PROMPT=0 GITHUB_PASSTOKEN= GITHUB_REPO_URL="https://github.com/$repo.git" \
    /bin/bash "$bootstrap_dir/init.sh"
)

# Wait until Bash has parsed the entire script, then give child processes the terminal instead of the download pipe.
if [[ -t 0 ]]; then
  main "$@"
elif { exec 3</dev/tty; } 2>/dev/null; then
  main "$@" <&3 3<&-
else
  fail '请在终端运行此命令，以便完成 GitHub 授权和安装。'
fi

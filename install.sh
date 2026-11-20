#!/bin/bash
set -euo pipefail

# Keep the original installation URL working while the source lives under dotfiles/.
forward() {
  curl -fsSL --connect-timeout 10 --max-time 60 \
    https://gaohongkui.github.io/setup/dotfiles/install.sh | /bin/bash -s -- "$@"
}

forward "$@"

#!/usr/bin/env bash
# =============================================================================
#  myshell-init — 一键初始化 zsh + tmux 环境
#  支持 macOS (Apple Silicon / Intel) 和 Linux (Debian/Ubuntu/Arch/CentOS/RHEL)
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
ARCH="$(uname -m)"

# ── 颜色 ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERR]${RESET}  $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}▶ $*${RESET}"; }

# ── OS 检测 ──────────────────────────────────────────────────────────────────
IS_MAC=false; IS_LINUX=false; IS_ARM=false; IS_CENTOS=false
[[ "$OS" == "Darwin" ]] && IS_MAC=true
[[ "$OS" == "Linux"  ]] && IS_LINUX=true
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && IS_ARM=true

# 检测 CentOS / RHEL / Rocky / AlmaLinux 系
if $IS_LINUX && [[ -f /etc/os-release ]]; then
  _os_id=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
  _os_like=$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2 | tr -d '"')
  case "$_os_id $_os_like" in *centos*|*rhel*|*rocky*|*alma*) IS_CENTOS=true ;; esac
  unset _os_id _os_like
fi

# ── EPEL 仓库（CentOS/RHEL 系需要，提供最新 zsh / tmux）────────────────────
ensure_epel() {
  $IS_CENTOS || return 0
  if ! rpm -q epel-release &>/dev/null; then
    info "安装 EPEL 仓库..."
    if command -v dnf &>/dev/null; then
      sudo dnf install -y epel-release
    else
      sudo yum install -y epel-release
    fi
  fi
}

# ── 包管理器 ─────────────────────────────────────────────────────────────────
install_pkg() {
  if $IS_MAC; then
    brew install "$@"
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y "$@"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$@"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$@"
  elif command -v yum &>/dev/null; then
    sudo yum install -y "$@"
  else
    error "未知包管理器，请手动安装: $*"; return 1
  fi
}

# 检查命令是否都已存在，全存在则跳过整组安装
all_exist() {
  for cmd in "$@"; do command -v "$cmd" &>/dev/null || return 1; done
}

# =============================================================================
# 1. Homebrew (macOS only)
# =============================================================================
step "Homebrew"
if $IS_MAC; then
  if ! command -v brew &>/dev/null; then
    info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Apple Silicon 路径
    if $IS_ARM; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
      local zprofile="$HOME/.zprofile"
      grep -qF 'brew shellenv' "$zprofile" 2>/dev/null || \
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$zprofile"
    fi
  else
    success "Homebrew 已存在"
  fi
else
  info "Linux 跳过 Homebrew"
fi

# =============================================================================
# 2. 基础工具
# =============================================================================
step "基础工具 (git curl wget)"
if $IS_LINUX; then
  ensure_epel   # CentOS/RHEL 系先确保 EPEL 就位
  if ! all_exist git curl wget unzip; then
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
    fi
    install_pkg git curl wget unzip
  else
    success "基础工具已存在"
  fi
elif $IS_MAC; then
  command -v git &>/dev/null || install_pkg git
fi

# =============================================================================
# 3. Zsh
# =============================================================================
step "Zsh"
if ! command -v zsh &>/dev/null; then
  info "安装 zsh..."
  install_pkg zsh
  if $IS_LINUX; then
    sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || \
      warn "无法自动切换默认 shell，请手动执行: chsh -s $(which zsh)"
  fi
else
  success "zsh $(zsh --version | awk '{print $2}') 已存在"
fi

# =============================================================================
# 4. Oh My Zsh
# =============================================================================
step "Oh My Zsh"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "安装 Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  success "Oh My Zsh 已存在"
fi

# =============================================================================
# 5. Powerlevel10k
# =============================================================================
step "Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
  info "安装 Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  success "Powerlevel10k 已存在"
fi

# =============================================================================
# 6. Nerd Font (MesloLGS NF)
# =============================================================================
step "Nerd Font — MesloLGS NF"
if $IS_MAC; then
  if brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
    success "MesloLGS NF 已安装"
  else
    info "安装 MesloLGS NF via Homebrew Cask..."
    brew tap homebrew/cask-fonts 2>/dev/null || true
    brew install --cask font-meslo-lg-nerd-font || \
      brew install --cask font-hack-nerd-font
  fi
elif $IS_LINUX; then
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  if ls "$FONT_DIR"/MesloLGS* &>/dev/null 2>&1; then
    success "MesloLGS NF 已存在"
  else
    info "下载 MesloLGS NF 字体..."
    BASE="https://github.com/romkatv/powerlevel10k-media/raw/master"
    for f in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" \
              "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
      curl -fsSL "$BASE/${f// /%20}" -o "$FONT_DIR/$f"
    done
    fc-cache -fv "$FONT_DIR" &>/dev/null
    success "MesloLGS NF 安装完成"
  fi
fi

# =============================================================================
# 7. iTerm2 (macOS only)
# =============================================================================
step "iTerm2"
if $IS_MAC; then
  if [[ -d "/Applications/iTerm.app" ]]; then
    success "iTerm2 已安装"
  else
    info "安装 iTerm2..."
    brew install --cask iterm2
  fi
else
  info "Linux 跳过 iTerm2（请使用系统终端并设置 MesloLGS NF 字体）"
fi

# =============================================================================
# 8. tmux
# =============================================================================
step "tmux"
if ! command -v tmux &>/dev/null; then
  info "安装 tmux..."
  install_pkg tmux
else
  success "tmux $(tmux -V | awk '{print $2}') 已存在"
fi

# =============================================================================
# 9. Oh My Tmux
# =============================================================================
step "Oh My Tmux"
if [[ ! -f "$HOME/.tmux.conf" ]] || ! grep -q "Oh my tmux" "$HOME/.tmux.conf" 2>/dev/null; then
  info "安装 Oh My Tmux..."
  git clone --depth=1 https://github.com/gpakosz/.tmux.git "$HOME/.tmux" 2>/dev/null || \
    git -C "$HOME/.tmux" pull
  ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
else
  success "Oh My Tmux 已存在"
fi

# =============================================================================
# 10. 复制配置文件
# =============================================================================
step "复制配置文件"

# 仅在内容不同时才备份并覆盖，避免重复执行产生垃圾备份
sync_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    # 目标是符号链接，直接覆盖（如 .tmux.conf 会是 symlink）
    cp "$src" "$dst"
    success "$dst 已更新"
    return
  fi
  if [[ -f "$dst" ]] && diff -q "$src" "$dst" &>/dev/null; then
    success "$dst 无变化，跳过"
    return
  fi
  [[ -f "$dst" ]] && cp "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)" && info "已备份 $dst"
  cp "$src" "$dst"
  success "$dst 已写入"
}

sync_file "$REPO_DIR/config/zshrc"          "$HOME/.zshrc"
sync_file "$REPO_DIR/config/p10k.zsh"       "$HOME/.p10k.zsh"
sync_file "$REPO_DIR/config/tmux.conf.local" "$HOME/.tmux.conf.local"

# tmux-help
mkdir -p "$HOME/.local/bin"
sync_file "$REPO_DIR/tmux-help.sh" "$HOME/.local/bin/tmux-help"
chmod +x "$HOME/.local/bin/tmux-help"

# =============================================================================
# 11. Snazzy 终端配色（Linux 自动尝试，macOS 提示手动导入）
# =============================================================================
step "Snazzy 终端配色"
if $IS_LINUX; then
  # 检测是否为 SSH 远程会话
  if [[ -n "${SSH_CLIENT:-}${SSH_TTY:-}${SSH_CONNECTION:-}" ]]; then
    warn "检测到 SSH 会话 — 颜色由【你本地 Mac/Windows 终端】渲染"
    echo -e "  ${YELLOW}请在你的本地终端（iTerm2 等）导入 Snazzy 配色，而不是在服务器上操作。${RESET}"
    echo -e "  配色文件已在服务器 ${CYAN}$REPO_DIR/themes/${RESET} 目录，可 scp 回本地使用。"
  # GNOME Terminal
  elif command -v gsettings &>/dev/null && \
       gsettings get org.gnome.Terminal.ProfilesList default &>/dev/null 2>&1; then
    info "检测到 GNOME Terminal，自动应用 Snazzy 配色..."
    bash "$REPO_DIR/themes/snazzy-gnome-terminal.sh" && \
      success "Snazzy 已应用到 GNOME Terminal"
  # Konsole (KDE)
  elif command -v konsole &>/dev/null; then
    info "检测到 Konsole，请手动导入配色："
    KONSOLE_DIR="$HOME/.local/share/konsole"
    mkdir -p "$KONSOLE_DIR"
    cp "$REPO_DIR/themes/Snazzy.colorscheme" "$KONSOLE_DIR/Snazzy.colorscheme" 2>/dev/null || true
    echo -e "  Konsole → Settings → Edit Current Profile → Appearance → Get New Schemes"
    echo -e "  或直接选择已复制到 ${CYAN}$KONSOLE_DIR/Snazzy.colorscheme${RESET} 的配色"
  # xfce4-terminal
  elif command -v xfce4-terminal &>/dev/null; then
    info "检测到 xfce4-terminal，请手动设置配色："
    echo -e "  xfce4-terminal → Edit → Preferences → Colors"
    echo -e "  将前景/背景色等参考 ${CYAN}$REPO_DIR/themes/snazzy-colors.txt${RESET} 手动填入"
  # Alacritty
  elif command -v alacritty &>/dev/null; then
    info "检测到 Alacritty，自动写入配色配置..."
    ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
    if [[ -f "$ALACRITTY_CONF" ]]; then
      if ! grep -q "snazzy" "$ALACRITTY_CONF"; then
        echo "" >> "$ALACRITTY_CONF"
        echo "import = [\"$REPO_DIR/themes/snazzy-alacritty.toml\"]" >> "$ALACRITTY_CONF"
        success "Snazzy 已写入 $ALACRITTY_CONF"
      else
        success "Alacritty 已有 snazzy 配置，跳过"
      fi
    else
      mkdir -p "$(dirname "$ALACRITTY_CONF")"
      echo "import = [\"$REPO_DIR/themes/snazzy-alacritty.toml\"]" > "$ALACRITTY_CONF"
      success "Snazzy 已写入 $ALACRITTY_CONF"
    fi
  # Kitty
  elif command -v kitty &>/dev/null; then
    info "检测到 Kitty，自动写入配色配置..."
    KITTY_CONF="$HOME/.config/kitty/kitty.conf"
    if [[ -f "$KITTY_CONF" ]]; then
      if ! grep -q "snazzy" "$KITTY_CONF"; then
        echo "" >> "$KITTY_CONF"
        echo "include $REPO_DIR/themes/snazzy-kitty.conf" >> "$KITTY_CONF"
        success "Snazzy 已写入 $KITTY_CONF"
      else
        success "Kitty 已有 snazzy 配置，跳过"
      fi
    else
      mkdir -p "$(dirname "$KITTY_CONF")"
      echo "include $REPO_DIR/themes/snazzy-kitty.conf" > "$KITTY_CONF"
      success "Snazzy 已写入 $KITTY_CONF"
    fi
  else
    warn "未能自动识别终端类型，请手动应用配色："
    echo -e "    ${CYAN}Alacritty${RESET}: import = [\"$REPO_DIR/themes/snazzy-alacritty.toml\"]"
    echo -e "    ${CYAN}Kitty${RESET}    : include $REPO_DIR/themes/snazzy-kitty.conf"
    echo -e "    ${CYAN}GNOME Terminal${RESET}: bash $REPO_DIR/themes/snazzy-gnome-terminal.sh"
  fi
elif $IS_MAC; then
  success "macOS: 请手动导入 iTerm2 配色（见安装完成提示）"
fi

# =============================================================================
# 完成提示
# =============================================================================
echo
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${RESET}"
echo -e "${GREEN}${BOLD}  安装完成！${RESET}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${RESET}"
echo
echo -e "  ${BOLD}后续步骤：${RESET}"
echo -e "  1. 重启终端或执行 ${CYAN}exec zsh${RESET}"
if $IS_MAC; then
  echo -e "  2. iTerm2 配色 → 导入 Snazzy 主题（${RED}必须${RESET}，否则颜色发暗）："
  echo -e "     iTerm2 → Preferences → Profiles → Colors → Color Presets → Import"
  echo -e "     选择文件: ${CYAN}$REPO_DIR/themes/Snazzy.itermcolors${RESET}"
  echo -e "     然后在 Text 标签页将字体设为 ${CYAN}MesloLGS NF 13${RESET}"
fi
echo -e "  3. 执行 ${CYAN}tmux${RESET} 进入 tmux 会话"
echo -e "  4. 执行 ${CYAN}tmux-help${RESET} 查看快捷键速查表"
echo
if $IS_LINUX; then
  echo -e "  ${YELLOW}Linux 配色说明：${RESET}"
  echo -e "  提示符颜色（目录蓝/命令符洋红等）依赖 ${BOLD}Snazzy 深色背景${RESET}才能正确渲染"
  echo -e "  配色文件位于 ${CYAN}$REPO_DIR/themes/${RESET}"
  echo -e "  GNOME Terminal → 已自动应用（若检测成功）"
  echo -e "  Alacritty     → 参考 themes/snazzy-alacritty.toml"
  echo -e "  Kitty         → 参考 themes/snazzy-kitty.conf"
fi
echo

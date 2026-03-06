#!/usr/bin/env bash
# =============================================================================
#  myshell-init — 一键初始化 zsh + tmux 环境
#  支持 macOS (Apple Silicon / Intel) 和 Linux (Debian/Ubuntu/Arch)
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
IS_MAC=false; IS_LINUX=false; IS_ARM=false
[[ "$OS" == "Darwin" ]] && IS_MAC=true
[[ "$OS" == "Linux"  ]] && IS_LINUX=true
[[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]] && IS_ARM=true

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
  else
    error "未知包管理器，请手动安装: $*"; return 1
  fi
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
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
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
if $IS_LINUX && command -v apt-get &>/dev/null; then
  sudo apt-get update -qq
  install_pkg git curl wget unzip
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

backup() {
  local f="$1"
  [[ -f "$f" && ! -L "$f" ]] && cp "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)" && \
    info "已备份 $f"
}

# .zshrc
backup "$HOME/.zshrc"
cp "$REPO_DIR/config/zshrc" "$HOME/.zshrc"
success ".zshrc 已写入"

# .p10k.zsh
backup "$HOME/.p10k.zsh"
cp "$REPO_DIR/config/p10k.zsh" "$HOME/.p10k.zsh"
success ".p10k.zsh 已写入"

# .tmux.conf.local
backup "$HOME/.tmux.conf.local"
cp "$REPO_DIR/config/tmux.conf.local" "$HOME/.tmux.conf.local"
success ".tmux.conf.local 已写入"

# tmux-help.sh
cp "$REPO_DIR/tmux-help.sh" "$HOME/.local/bin/tmux-help" 2>/dev/null || {
  mkdir -p "$HOME/.local/bin"
  cp "$REPO_DIR/tmux-help.sh" "$HOME/.local/bin/tmux-help"
}
chmod +x "$HOME/.local/bin/tmux-help"
success "tmux-help 已安装到 ~/.local/bin/tmux-help"

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
  echo -e "  2. 打开 iTerm2 → Preferences → Profiles → Text"
  echo -e "     字体设置为 ${CYAN}MesloLGS NF${RESET}，大小 13-14"
fi
echo -e "  3. 执行 ${CYAN}tmux${RESET} 进入 tmux 会话"
echo -e "  4. 执行 ${CYAN}tmux-help${RESET} 查看快捷键速查表"
echo
if $IS_MAC; then
  echo -e "  ${YELLOW}提示：如 iTerm2 字体显示异常，在 Profiles > Text 中"
  echo -e "  勾选 Use a different font for non-ASCII text 并选 MesloLGS NF${RESET}"
fi
echo

# myshell-init

一键初始化 zsh + tmux 环境，支持 **macOS**（Apple Silicon / Intel）和 **Linux**（Debian/Ubuntu/Arch/Fedora）。

## 包含内容

| 组件 | 说明 |
|------|------|
| **Homebrew** | macOS 包管理器（macOS only） |
| **Zsh** | Shell 本体 |
| **Oh My Zsh** | Zsh 插件框架 |
| **Powerlevel10k** | 极速 Pure 风格提示符 |
| **MesloLGS NF** | Nerd Font 字体（图标支持） |
| **iTerm2** | 终端模拟器（macOS only） |
| **tmux** | 终端复用器 |
| **Oh My Tmux** | tmux 配置框架（gpakosz/.tmux） |

## 快速开始

```bash
git clone git@github.com:hi-wayne/myshell-init.git ~/myshell-init
cd ~/myshell-init
bash install.sh
```

安装完成后重启终端，执行 `exec zsh` 生效配置。

## 安装后步骤

### macOS / iTerm2

1. 打开 iTerm2 → `Preferences` → `Profiles` → `Text`
2. 字体改为 **MesloLGS NF**，大小建议 13-14
3. 如需彻底还原颜色风格，可导入 iTerm2 配色方案（见下方）

### Linux

在终端模拟器（GNOME Terminal / Alacritty / Kitty 等）的字体设置中选择 **MesloLGS NF**。

## 配置文件说明

```
config/
├── zshrc          → ~/.zshrc         (Oh My Zsh + P10k + 状态栏)
├── p10k.zsh       → ~/.p10k.zsh      (Pure 风格 Powerlevel10k 主题)
└── tmux.conf.local→ ~/.tmux.conf.local (Oh My Tmux 自定义配置)

tmux-help.sh       → ~/.local/bin/tmux-help  (tmux 快捷键速查表)
```

## tmux 快捷键速查

安装后执行：

```bash
tmux-help
```

### 核心快捷键一览

> 前缀键 = `Ctrl+a`（主）或 `Ctrl+b`（备用）

#### 面板

| 快捷键 | 功能 |
|--------|------|
| `prefix + -` | 水平分屏（上下） |
| `prefix + =` | 垂直分屏（左右） |
| `prefix + h/j/k/l` | 移动焦点（vim 方向） |
| `prefix + H/J/K/L` | 调整面板大小 |
| `prefix + x` | 关闭当前面板 |
| `prefix + +` | 最大化 / 还原面板 |
| `prefix + >` / `<` | 与相邻面板对调 |
| `prefix + q` | 显示面板编号 |

#### 窗口

| 快捷键 | 功能 |
|--------|------|
| `prefix + c` | 新建窗口 |
| `prefix + ,` | 重命名窗口 |
| `prefix + Tab` | 切换到上一个活动窗口 |
| `prefix + Ctrl+h/l` | 切换到前/后窗口 |
| `prefix + 0-9` | 按编号跳转窗口 |
| `prefix + &` | 关闭窗口 |

#### 会话

| 快捷键 | 功能 |
|--------|------|
| `prefix + Ctrl+c` | 新建会话 |
| `prefix + s` | 列出所有会话 |
| `prefix + d` | 脱离会话（后台保留） |
| `prefix + $` | 重命名会话 |
| `prefix + Ctrl+f` | 按名称搜索会话 |

#### 复制模式（Vi 风格）

| 快捷键 | 功能 |
|--------|------|
| `prefix + Enter` | 进入复制模式 |
| `v` | 开始选择 |
| `y` | 复制（同步到系统剪贴板） |
| `H` / `L` | 跳到行首 / 行尾 |
| `/` / `?` | 向下 / 向上搜索 |
| `Escape` | 退出复制模式 |
| `prefix + p` | 粘贴 |

#### 其他

| 快捷键 | 功能 |
|--------|------|
| `prefix + S` | 开关同步输入（所有 pane 同时执行） |
| `prefix + m` | 开关鼠标模式 |
| `prefix + r` | 重新加载配置 |
| `prefix + e` | 编辑 .tmux.conf.local |
| `prefix + t` | 显示时钟 |
| `prefix + ?` | 查看全部快捷键 |
| `Ctrl+l`（无前缀） | 清屏并清除历史 |

## 机器特有配置

`~/.zshrc.local`（不在此 repo 中）可放置机器特有设置，如 Java、Maven 路径等。在 `~/.zshrc` 末尾取消注释以下行即可：

```zsh
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

## 卸载

```bash
# 删除 Oh My Zsh
uninstall_oh_my_zsh

# 删除 Oh My Tmux
rm -rf ~/.tmux ~/.tmux.conf ~/.tmux.conf.local

# 删除 p10k
rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k ~/.p10k.zsh
```

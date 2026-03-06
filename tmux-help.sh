#!/usr/bin/env bash
# tmux 快捷键速查表 — 自适应当前 pane 尺寸

# ── 颜色 ─────────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
C_TITLE='\033[1;36m'   # 青色加粗
C_SEC='\033[1;33m'     # 黄色加粗（章节标题）
C_KEY='\033[1;32m'     # 绿色加粗（按键）
C_DESC='\033[0;37m'    # 浅灰（描述）
C_SEP='\033[0;34m'     # 蓝色（分隔线）
C_PREFIX='\033[1;35m'  # 洋红加粗（前缀提示）

# ── 终端尺寸 ──────────────────────────────────────────────────────────────────
COLS=$(tput cols 2>/dev/null || echo 80)
ROWS=$(tput lines 2>/dev/null || echo 24)

# ── 工具函数 ──────────────────────────────────────────────────────────────────
repeat() { printf '%*s' "$2" '' | tr ' ' "$1"; }

hline() {
    echo -e "${C_SEP}$(repeat '─' "$COLS")${RESET}"
}

thin_line() {
    echo -e "${C_SEP}$(repeat '·' "$COLS")${RESET}"
}

center() {
    local text="$1"
    local plain
    plain=$(printf '%b' "$text" | sed 's/\033\[[0-9;]*m//g')
    local len=${#plain}
    local pad=$(( (COLS - len) / 2 ))
    printf '%*s' "$pad" ''
    printf '%b\n' "$text"
}

row() {
    local key="$1"
    local desc="$2"
    local key_col=22
    local desc_col=$(( COLS - key_col - 4 ))
    if [[ ${#desc} -gt $desc_col && $desc_col -gt 4 ]]; then
        desc="${desc:0:$(( desc_col - 1 ))}…"
    fi
    printf "  ${C_KEY}%-${key_col}s${RESET}  ${C_DESC}%s${RESET}\n" "$key" "$desc"
}

section() {
    echo
    echo -e "  ${C_SEC}${BOLD}$1${RESET}"
    thin_line
}

# ── 双列布局（宽屏时启用）────────────────────────────────────────────────────
declare -a COL_ENTRIES=()

add() { COL_ENTRIES+=("$1|$2"); }

flush_two_col() {
    local col_w=$(( (COLS - 6) / 2 ))
    local key_w=20
    local desc_w=$(( col_w - key_w - 3 ))
    [[ $desc_w -lt 8 ]] && desc_w=8

    local i=0
    local total=${#COL_ENTRIES[@]}
    while [[ $i -lt $total ]]; do
        local left="${COL_ENTRIES[$i]}"
        local lk="${left%%|*}"
        local ld="${left##*|}"
        local right=""
        local rk="" rd=""
        if [[ $(( i + 1 )) -lt $total ]]; then
            right="${COL_ENTRIES[$((i+1))]}"
            rk="${right%%|*}"
            rd="${right##*|}"
        fi

        [[ ${#ld} -gt $desc_w ]] && ld="${ld:0:$(( desc_w - 1 ))}…"
        [[ ${#rd} -gt $desc_w ]] && rd="${rd:0:$(( desc_w - 1 ))}…"

        if [[ -n $right ]]; then
            printf "  ${C_KEY}%-${key_w}s${RESET} ${C_DESC}%-${desc_w}s${RESET}   ${C_KEY}%-${key_w}s${RESET} ${C_DESC}%s${RESET}\n" \
                "$lk" "$ld" "$rk" "$rd"
        else
            printf "  ${C_KEY}%-${key_w}s${RESET} ${C_DESC}%s${RESET}\n" "$lk" "$ld"
        fi
        (( i += 2 ))
    done
    COL_ENTRIES=()
}

flush_single_col() {
    for entry in "${COL_ENTRIES[@]}"; do
        local k="${entry%%|*}"
        local d="${entry##*|}"
        row "$k" "$d"
    done
    COL_ENTRIES=()
}

flush() {
    if [[ $COLS -ge 100 ]]; then
        flush_two_col
    else
        flush_single_col
    fi
}

# ── 主输出 ────────────────────────────────────────────────────────────────────
clear

hline
center "${C_TITLE}${BOLD}  TMUX 快捷键速查表  ${RESET}"
center "${DIM}oh-my-tmux  |  $(repeat '─' 20)  |  前缀键 = Ctrl+a  或  Ctrl+b${RESET}"
hline

# 前缀键说明
echo
echo -e "  ${C_PREFIX}${BOLD}前缀键${RESET}  — 以下所有快捷键都需要先按前缀键"
printf "  ${C_KEY}%-22s${RESET}  ${C_DESC}%s${RESET}\n" "Ctrl+a" "主前缀（oh-my-tmux 默认）"
printf "  ${C_KEY}%-22s${RESET}  ${C_DESC}%s${RESET}\n" "Ctrl+b" "备用前缀（tmux 原生）"

# ── 面板 ──────────────────────────────────────────────────────────────────────
section "面板 — 分屏与管理"
add "prefix + -"         "水平分屏（上下）"
add "prefix + ="         "垂直分屏（左右）"
add "prefix + x"         "关闭当前面板"
add "prefix + q"         "显示面板编号"
add "prefix + +"         "最大化 / 还原当前面板"
add "prefix + >"         "与下一个面板对调"
add "prefix + <"         "与上一个面板对调"
flush

section "面板 — 焦点移动"
add "prefix + h"         "移到左边面板"
add "prefix + l"         "移到右边面板"
add "prefix + j"         "移到下面面板"
add "prefix + k"         "移到上面面板"
flush

section "面板 — 调整大小（可持续按）"
add "prefix + H"         "向左扩大"
add "prefix + L"         "向右扩大"
add "prefix + J"         "向下扩大"
add "prefix + K"         "向上扩大"
flush

# ── 窗口 ──────────────────────────────────────────────────────────────────────
section "窗口"
add "prefix + c"         "新建窗口"
add "prefix + &"         "关闭窗口"
add "prefix + ,"         "重命名窗口"
add "prefix + Tab"       "切换到上一个活动窗口"
add "prefix + Ctrl+h"    "切换到前一个窗口（可持续按）"
add "prefix + Ctrl+l"    "切换到后一个窗口（可持续按）"
add "prefix + 0-9"       "按编号直接跳转窗口"
add "prefix + C-S-H"     "把当前窗口向左移"
add "prefix + C-S-L"     "把当前窗口向右移"
flush

# ── 会话 ──────────────────────────────────────────────────────────────────────
section "会话 — 创建 / 切换"
add "prefix + Ctrl+c"    "新建会话"
add "prefix + Ctrl+f"    "按名称搜索并切换会话"
add "prefix + s"         "列出所有会话（可交互选择）"
add "prefix + Shift+Tab" "切换到上一个会话"
add "prefix + d"         "脱离当前会话（后台保留，detach）"
flush

section "会话 — 改名 / 删除"
add "prefix + \$"        "重命名当前会话"
add "prefix + :"         "进入命令模式，然后输入："
add "  kill-session"     "  删除当前会话"
add "  kill-session -t 名称" "  删除指定会话"
add "  kill-server"      "  删除全部会话并退出 tmux"
flush

# ── 复制模式 ──────────────────────────────────────────────────────────────────
section "复制模式（Vi 风格）"
add "prefix + Enter"     "进入复制模式"
add "v"                  "开始选择"
add "Ctrl+v"             "矩形选择"
add "y"                  "复制（自动同步到 macOS 剪贴板）"
add "H / L"              "跳到行首 / 行尾"
add "/ 或 ?"             "向下 / 向上搜索"
add "n / N"              "下一个 / 上一个搜索结果"
add "Escape"             "退出复制模式"
add "prefix + p"         "粘贴缓冲区"
add "prefix + b"         "列出所有粘贴缓冲区"
flush

# ── 同步输入 ──────────────────────────────────────────────────────────────────
section "同步输入（所有 pane 同时执行）"
add "prefix + S"         "一键开启 / 关闭同步输入，状态栏有提示"
add "prefix + :"         "进入命令模式，也可手动输入："
add "  setw synchronize-panes on"  "  开启同步"
add "  setw synchronize-panes off" "  关闭同步"
flush

# ── 其他 ──────────────────────────────────────────────────────────────────────
section "其他"
add "prefix + r"         "重新加载配置文件"
add "prefix + e"         "编辑 .tmux.conf.local"
add "prefix + m"         "开关鼠标模式"
add "prefix + t"         "显示时钟"
add "prefix + ?"         "查看全部快捷键"
add "Ctrl+l（无前缀）"   "清屏并清除历史"
flush

# ── 页脚 ──────────────────────────────────────────────────────────────────────
echo
hline
center "${DIM}当前 pane 尺寸：${COLS}x${ROWS}  |  Ctrl+c 退出${RESET}"
hline
echo

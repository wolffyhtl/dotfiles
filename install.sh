#!/usr/bin/env bash

# ==============================================================================
# dotfiles Fedora 一键部署脚本
#
# 功能:
#   1. 菜单选择桌面组件组合（方向键操作）
#   2. 自动安装所有依赖（dnf / cargo / pip / 字体）
#   3. 配置 Oh My Zsh + Powerlevel10k + 插件
#   4. 符号链接 dotfiles
#   5. 按配置生成 niri spawn.kdl
# ==============================================================================

set -euo pipefail

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'
INV='\033[7m'      # 反白
NINV='\033[27m'    # 取消反白
CLR='\033[K'       # 清除到行尾
UPL='\033[A\033[K' # 上移一行并清除


# --- 常量 ---
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
FEDORA_VERSION="$(rpm -E %fedora 2>/dev/null || true)"
PROFILE=""

# --- 基础函数 ---

cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if ! cmd_exists sudo; then
            printf "%bError: sudo not found. Run this script as root.%b\n" "$RED" "$NC"
            exit 1
        fi
        sudo "$@"
    fi
}

# --- 文件链接 ---

link_file() {
    local src="$1" dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local current
        current="$(readlink "$dest" 2>/dev/null || true)"
        if [ "$current" = "$src" ]; then
            return 0
        fi
        mkdir -p "$BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
        printf "%b备份: %s -> %s%b\n" "$BLUE" "$dest" "$BACKUP_DIR" "$NC"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    printf "%b链接: %s -> %s%b\n" "$GREEN" "$dest" "$src" "$NC"
}

link_top_level() {
    local file basename

    for file in "$DOTFILES_DIR"/.??*; do
        basename="$(basename "$file")"
        case "$basename" in
            .git | .config) continue ;;
        esac
        [ -f "$file" ] || continue
        link_file "$file" "$HOME/$basename"
    done
}

link_config_dir() {
    local dir="$1" entry basename

    for entry in "$DOTFILES_DIR/.config/$dir"*; do
        [ -e "$entry" ] || continue
        basename="$(basename "$entry")"
        [ "$basename" = "config.toml" ] && [ "$dir" = "matugen" ] && continue
        link_file "$entry" "$HOME/.config/$basename"
    done
}

# --- 交互菜单（方向键 + Enter） ---

arrow_menu() {
    local title="$1"
    shift
    local items=("$@")
    local selected=0
    local old_stty

    old_stty="$(stty -g 2>/dev/null || true)"
    stty -echo
    tput civis 2>/dev/null || true
    trap 'stty "$old_stty" 2>/dev/null || true; tput cnorm 2>/dev/null || true; tput ed 2>/dev/null || true' RETURN

    _draw() {
        local i
        printf "%b\n" "$title"
        for ((i = 0; i < ${#items[@]}; i++)); do
            if [ "$i" -eq "$selected" ]; then
                printf "%b > %b%b%b\n" "  ${INV}" "${items[$i]}" "${NINV}" "${CLR}"
            else
                printf "   %b%b\n" "${items[$i]}" "${CLR}"
            fi
        done
    }

    _clear() {
        local i
        for ((i = 0; i <= ${#items[@]}; i++)); do
            printf "%b" "${UPL}"
        done
    }

    _draw
    while true; do
        local key
        read -rsn1 key
        if [ "$key" = $'\e' ]; then
            read -rsn2 key 2>/dev/null || true
            case "$key" in
                '[A')
                    [ "$selected" -gt 0 ] && selected=$((selected - 1))
                    ;;
                '[B')
                    [ "$selected" -lt "$((${#items[@]} - 1))" ] && selected=$((selected + 1))
                    ;;
            esac
        elif [ -z "$key" ]; then
            break
        fi
        _clear
        _draw
    done

    _clear
    printf "%b> %b%b\n" "${GREEN}" "${items[$selected]}" "${NC}"
    printf "\n"
    return "$selected"
}

select_profile() {
    local items=(
        "waybar + mako + copyq + fuzzel"
        "DankMaterialShell (dms)"
        "Noctalia"
        "${RED}取消安装${NC}"
    )

    arrow_menu "${BLUE}--- 选择桌面组件组合（方向键 / Enter 确认）${NC}" "${items[@]}"

    case "$?" in
        0) PROFILE="waybar" ;;
        1) PROFILE="dms" ;;
        2) PROFILE="noctalia" ;;
        3)
            printf "%b安装已取消%b\n" "$YELLOW" "$NC"
            exit 0
            ;;
    esac
}

# --- 系统包安装 ---

install_packages() {
    printf "%b>>> 添加软件源...%b\n" "$BLUE" "$NC"
    run_as_root dnf install -y --nogpgcheck \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
        2>/dev/null || true
    run_as_root dnf copr enable -y solopasha/hyprland 2>/dev/null || true
    run_as_root dnf copr enable -y scottames/awww 2>/dev/null || true
    run_as_root dnf copr enable -y eddsalkield/swaylock-effects 2>/dev/null || true
    run_as_root dnf copr enable -y avengemedia/dms 2>/dev/null || true

    local common=(
        alacritty swaylock-effects fuzzel wlogout swaybg swayidle
        grim slurp satty swappy wf-recorder wl-clipboard
        cava btop fastfetch
        fcitx5 fcitx5-rime neovim starship yazi
        xarchiver caja pavucontrol playerctl brightnessctl
        power-profiles-daemon NetworkManager NetworkManager-tui
        blueman libnotify ImageMagick jq inotify-tools
        xorg-xprop fzf fish zsh git
        jetbrains-mono-fonts fontawesome-fonts
        adw-gtk3-theme mate-polkit python3-pip ffmpeg
        niri wl-screenrec matugen
    )

    local extra=()
    case "$PROFILE" in
        waybar)  extra=(waybar mako copyq awww waypaper) ;;
        dms)     extra=(dms) ;;
        noctalia) extra=(noctalia) ;;
    esac

    printf "%b>>> 安装系统包 (通用 + %s)...%b\n" "$BLUE" "$PROFILE" "$NC"
    run_as_root dnf install -y "${common[@]}" "${extra[@]}"
    printf "%b系统包安装完成%b\n" "$GREEN" "$NC"
}

# --- Oh My Zsh ---

install_ohmyzsh() {
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        printf "%b>>> 安装 Oh My Zsh...%b\n" "$BLUE" "$NC"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        printf "%bOh My Zsh 安装完成%b\n" "$GREEN" "$NC"
    fi

    if [ ! -d "$custom/themes/powerlevel10k" ]; then
        printf "%b>>> 安装 Powerlevel10k...%b\n" "$BLUE" "$NC"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
        printf "%bPowerlevel10k 安装完成%b\n" "$GREEN" "$NC"
    fi

    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    local entry name url
    for entry in "${plugins[@]}"; do
        name="${entry%%:*}"
        url="${entry##*:}"
        if [ ! -d "$custom/plugins/$name" ]; then
            printf "%b>>> 安装 zsh 插件 %s...%b\n" "$BLUE" "$name" "$NC"
            git clone "$url" "$custom/plugins/$name"
            printf "%b%s 安装完成%b\n" "$GREEN" "$name" "$NC"
        fi
    done
}

# --- 字体 ---

install_fonts() {
    if fc-list :lang=zh 2>/dev/null | grep -qi "MapleMono"; then
        return 0
    fi

    local version="v7.9"
    local zip="MapleMono-NF-CN.zip"
    local dest="$HOME/.local/share/fonts"

    printf "%b>>> 下载 Maple Mono NF CN 字体...%b\n" "$BLUE" "$NC"
    mkdir -p "$dest"
    wget -q "https://github.com/subframe7536/Maple-font/releases/download/${version}/${zip}" -O "/tmp/${zip}"
    unzip -qo "/tmp/${zip}" -d "$dest" 2>/dev/null
    fc-cache -f "$dest" 2>/dev/null
    printf "%bMaple Mono NF CN 字体安装完成%b\n" "$GREEN" "$NC"
}

# --- 链接 dotfiles ---

link_dotfiles() {
    local common_dirs=(
        alacritty btop caja caja-actions cava fastfetch fcitx5 fish
        gtk-3.0 gtk-4.0 matugen niri nvim scripts swaylock
        swayosd wlogout xarchiver yazi
    )
    local common_files=(mimeapps.list sealert.conf starship.toml)

    printf "%b>>> 链接 dotfiles...%b\n" "$BLUE" "$NC"
    link_top_level

    local dir
    for dir in "${common_dirs[@]}"; do
        link_config_dir "$dir"
    done

    local f
    for f in "${common_files[@]}"; do
        [ -f "$DOTFILES_DIR/.config/$f" ] && link_file "$DOTFILES_DIR/.config/$f" "$HOME/.config/$f"
    done

    case "$PROFILE" in
        waybar)   link_config_dir "waybar"; link_config_dir "mako"; link_config_dir "copyq"; link_config_dir "fuzzel"; link_config_dir "waypaper" ;;
        dms)      link_config_dir "DankMaterialShell" ;;
        noctalia) link_config_dir "noctalia" ;;
    esac

    printf "%bdotfiles 链接完成%b\n" "$GREEN" "$NC"
}

# --- 按配置生成文件 ---

write_matugen_config() {
    local src="$DOTFILES_DIR/.config/matugen/config.toml"
    local dest="$HOME/.config/matugen/config.toml"
    local cmd

    case "$PROFILE" in
        waybar)   cmd="awww" ;;
        dms)      cmd="dms ipc call wallpaper set" ;;
        noctalia) cmd="noctalia msg wallpaper-set" ;;
    esac

    mkdir -p "$HOME/.config/matugen"
    sed "s|^command = '.*'|command = '${cmd}'|" "$src" > "$dest"
    printf "%bmatugen 配置已生成（壁纸: %s）%b\n" "$GREEN" "$cmd" "$NC"
}

write_spawn_kdl() {
    local file="$HOME/.config/niri/spawn.kdl"

    mkdir -p "$HOME/.config/niri"

    case "$PROFILE" in
        waybar)
            cat > "$file" << 'KDL'
// Profile: waybar + mako + copyq + fuzzel
spawn-at-startup "waybar"
spawn-at-startup "mako"
spawn-at-startup "copyq"
KDL
            ;;
        dms)
            cat > "$file" << 'KDL'
// Profile: DankMaterialShell
spawn-at-startup "dms"
KDL
            ;;
        noctalia)
            cat > "$file" << 'KDL'
// Profile: Noctalia（自带栏、启动器、通知、剪贴板）
spawn-at-startup "noctalia"
KDL
            ;;
    esac

    printf "%bniri spawn.kdl 已生成（%s）%b\n" "$GREEN" "$PROFILE" "$NC"
}

# --- 杂项 ---

disable_arch_check_updates() {
    local target="$HOME/.config/waybar/scripts/check-updates.sh"

    if [ -L "$target" ]; then
        mv "$target" "${target}.disabled" 2>/dev/null || true
        printf "%bcheck-updates.sh 为 Arch 专用，已禁用%b\n" "$YELLOW" "$NC"
    fi
}

change_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        return 0
    fi

    printf "%b>>> 切换默认 shell 为 zsh...%b\n" "$BLUE" "$NC"
    chsh -s "$(which zsh)"
    printf "%b默认 shell 已切换为 zsh，重新登录生效%b\n" "$GREEN" "$NC"
}

# ==============================================================================
# 主流程
# ==============================================================================

printf "\n"
printf "%b================================%b\n" "$CYAN" "$NC"
printf "%b  dotfiles Fedora 一键部署%b\n" "$CYAN" "$NC"
printf "%b================================%b\n" "$CYAN" "$NC"
printf "\n"

if [ -z "$FEDORA_VERSION" ]; then
    printf "%bError: 此脚本仅支持 Fedora Linux%b\n" "$RED" "$NC"
    exit 1
fi
printf "%b系统检测: Fedora %s x86_64%b\n" "$GREEN" "$FEDORA_VERSION" "$NC"

select_profile
printf "%b已选择: %s%b\n" "$GREEN" "$PROFILE" "$NC"

printf "%b>>> 准备安装环境...%b\n" "$BLUE" "$NC"
run_as_root true  # 提前缓存 sudo 凭据

install_packages
install_ohmyzsh
install_fonts
link_dotfiles
write_matugen_config
write_spawn_kdl
disable_arch_check_updates
change_shell

printf "\n"
printf "%b全部完成！%b\n" "$GREEN" "$NC"
printf "  %b备份目录:%b %s\n" "$BLUE" "$NC" "$BACKUP_DIR"
printf "  %b当前配置:%b %s\n" "$BLUE" "$NC" "$PROFILE"
printf "\n"
printf "  后续步骤:\n"
printf "    1. 重新登录或重启\n"
printf "    2. 运行 ~/.config/scripts/matugen-update.sh 生成主题\n"
printf "    3. 在登录管理器中选择 niri 进入 Wayland 会话\n"
printf "\n"
printf "%b如需切换配置，重新运行 install.sh 即可%b\n" "$YELLOW" "$NC"

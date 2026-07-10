#!/usr/bin/env bash
# 遇到错误立即退出
set -e

# 获取脚本所在目录（即 ~/dotfiles）
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

echo "🚀 开始部署 Dotfiles (Fedora + Niri)..."

# --------------------------------------------------------------
# 1. 安装系统依赖 (dnf)
# --------------------------------------------------------------
echo "📦 正在安装必要软件包 (需要 sudo 权限)..."
sudo dnf install -y \
    stow \
    git \
    curl \
    zsh \
    alacritty \
    niri \
    waybar \
    mako \
    fuzzel \
    neovim \
    btop \
    fastfetch \
    fzf \
    ripgrep \
    fd-find \
    bat \
    brightnessctl \
    playerctl

# --------------------------------------------------------------
# 2. 安装 Oh-My-Zsh (如果尚未安装)
# --------------------------------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "正在安装 Oh-My-Zsh..."
    # RUNZSH=no 防止安装完成后自动进入新 shell 中断脚本
    # CHSH=no 防止自动修改默认 shell (我们手动处理)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh-My-Zsh 已存在，跳过安装。"
fi

git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

cp .zshrc ~/
cp .vimrc ~/
cp .p10k.zsh ~/
cp -r .config/* ~/.config/

chsh -s /usr/bin/zsh
# --------------------------------------------------------------
# 3. 完成提示
# --------------------------------------------------------------
echo ""
echo "Dotfiles 部署完成！"

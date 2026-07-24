# dotfiles

个人 Fedora 桌面配置文件集，覆盖 niri 合成器、Noctalia/waybar/DankMaterialShell 三种桌面组合。

## 快速开始

```bash
git clone https://github.com/你的用户名/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

脚本会弹出菜单，选择桌面组件组合后自动安装所有依赖并链接配置。

## 桌面组件组合

| 组件 | waybar 组合 | DMS 组合 | Noctalia 组合 |
|------|-------------|----------|---------------|
| 合成器 | niri | niri | niri |
| 状态栏 | waybar | dms 面板 | Noctalia 栏 |
| 通知 | mako | dms 内置 | Noctalia 内置 |
| 剪贴板 | copyq | dms 内置 | Noctalia 内置 |
| 启动器 | fuzzel | dms 内置 | Noctalia 内置 |
| 锁屏 | swaylock | swaylock | swaylock |
| 截图 | grim+slurp+satty | 同上 | 同上 |
| 主题生成 | matugen | matugen | matugen（自带集成） |

## 包含的配置

| 类别 | 应用 |
|------|------|
| Shell | zsh (Oh My Zsh + Powerlevel10k), starship, fish |
| 编辑器 | nvim (LazyVim) |
| 终端 | alacritty |
| 文件管理器 | caja, yazi |
| 输入法 | fcitx5 (Rime) |
| 系统监控 | btop, fastfetch |
| 壁纸 | waypaper / awww (waybar)、noctalia 内置 (Noctalia)、dms 内置 (DMS) |
| 音频可视化 | cava |
| 其他 | GTK, scripts, wlogout 等 |

## 目录结构

```
~/.dotfiles/
├── .zshrc                  # Zsh 配置
├── .vimrc                  # Vim 配置
├── .p10k.zsh               # Powerlevel10k 主题配置
├── install.sh              # 一键部署脚本
└── .config/
    ├── alacritty/          # 终端模拟器
    ├── niri/               # Niri 合成器配置 + spawn.kdl（按配置生成）
    ├── waybar/             # waybar 状态栏（组合 1）
    ├── mako/               # mako 通知（组合 1）
    ├── copyq/              # copyq 剪贴板（组合 1）
    ├── fuzzel/             # fuzzel 启动器（组合 1）
    ├── DankMaterialShell/  # DMS 配置（组合 2）
    ├── noctalia/           # Noctalia 配置（组合 3）
    ├── nvim/               # Neovim
    ├── fcitx5/             # 输入法
    ├── btop/               # 系统监控
    ├── fastfetch/           # 系统信息
    ├── scripts/            # 自定义脚本
    ├── swaylock/           # 锁屏
    ├── wlogout/            # 关机菜单
    ├── yazi/               # 终端文件管理器
    └── ...
```

## 依赖

脚本自动处理以下依赖：

- **dnf 包**: niri, alacritty, waybar, neovim, fcitx5 等
- **COPR**: solopasha/niri, solopasha/hyprland
- **Cargo**: matugen, 以及按组合安装 awww / noctalia / dankmaterialshell
- **pip**: waypaper
- **Oh My Zsh** + Powerlevel10k + zsh-autosuggestions + zsh-syntax-highlighting
- **Maple Mono NF CN** 字体（手动下载安装）

#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# APT 镜像源切换（适配 Ubuntu 系统）
function switch_apt_mirror() {
    local sources_list="/etc/apt/sources.list"

    if [[ "$1" == "domestic" ]]; then
        echo "Switching to domestic APT mirror..."
        # 备份 sources.list（若备份文件已存在，则覆盖）
        if [[ ! -f "${sources_list}.bak" ]]; then
            sudo cp "$sources_list" "${sources_list}.bak"
        else
            echo "Backup file ${sources_list}.bak already exists, overwriting..."
            sudo cp "$sources_list" "${sources_list}.bak"
        fi

        # 写入国内镜像配置（此处以 USTC 镜像为例，根据实际需要调整）
        sudo tee "$sources_list" > /dev/null << EOF
deb http://mirrors.ustc.edu.cn/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ xenial main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ xenial-security main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ xenial-updates main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ xenial-proposed main restricted universe multiverse
deb-src http://mirrors.ustc.edu.cn/ubuntu/ xenial-backports main restricted universe multiverse
EOF
    else
        echo "Switching back to default APT mirror..."
        if [[ -f "${sources_list}.bak" ]]; then
            sudo mv -f "${sources_list}.bak" "$sources_list"
        else
            echo "Backup file not found. Cannot restore default mirror."
            return 1
        fi
    fi

    echo "Updating and upgrading system packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y
}

# Conda 镜像源切换
function switch_conda_mirror() {
    if [[ "$1" == "domestic" ]]; then
        echo "Switching to domestic Conda mirror..."
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
        conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/linux-64/
    else
        echo "Switching back to default Conda mirror..."
        conda config --remove-key channels
    fi
    conda config --set show_channel_urls yes
}

# Pip 镜像源切换
function switch_pip_mirror() {
    local pip_config_file="$HOME/.pip/pip.conf"
    if [[ "$1" == "domestic" ]]; then
        echo "Switching to domestic Pip mirror..."
        mkdir -p "$(dirname "$pip_config_file")"
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    else
        echo "Switching back to default Pip mirror..."
        pip config unset global.index-url
    fi
}

# 主菜单
function main_menu() {

    echo -e "${GREEN}******** Mirror Switch Menu *********${RESET}"
    echo -e "${GREEN} 1.  Switch to Domestic Mirrors${RESET}"
    echo -e "${GREEN} 2.  Switch to Default Mirrors${RESET}"
    echo -e "${GREEN}*************************************${RESET}"

    read -rp "Enter your choice: " choice

    case "$choice" in
        1)
            switch_apt_mirror "domestic"
            switch_conda_mirror "domestic"
            switch_pip_mirror "domestic"
            ;;
        2)
            switch_apt_mirror "default"
            switch_conda_mirror "default"
            switch_pip_mirror "default"
            ;;
        *)
            echo "Invalid selection"
            ;;
    esac
}

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script requires root privileges!${RESET}"
    echo -e "${YELLOW}Try running: sudo $0${RESET}"
    read -rp "Do you want to restart with sudo? (y/N): " choice
    case $choice in
        [Yy]* ) exec sudo bash "$0";;
        * ) echo "Exiting script. Please run as root."; exec bash; exit 1;;
    esac
fi

main_menu
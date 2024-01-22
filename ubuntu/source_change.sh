#!/bin/bash

# APT 镜像源切换
function switch_apt_mirror() {
    local sources_list="/etc/apt/sources.list"

    if [ "$1" == "domestic" ]; then
        echo "Switching to domestic APT mirror..."
        sudo cp $sources_list "${sources_list}.bak"
        sudo tee $sources_list > /dev/null << EOF
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
        sudo mv -f "${sources_list}.bak" $sources_list
    fi
    sudo apt-get update -y
    sudo apt-get upgrade -y
}

# Conda 镜像源切换（与 CentOS 7 脚本相同）
function switch_conda_mirror() {
    # 省略，与 CentOS 7 脚本中的函数相同
}

# Pip 镜像源切换（与 CentOS 7 脚本相同）
function switch_pip_mirror() {
    # 省略，与 CentOS 7 脚本中的函数相同
}

# 主菜单
function main_menu() {
    echo -e "\033[32m Makesure we have su permission \033[0m"
    echo "1. Switch to Domestic Mirrors"
    echo "2. Switch to Default Mirrors"
    read -p "Enter your choice: " choice

    case $choice in
        1) switch_apt_mirror "domestic"
           switch_conda_mirror "domestic"
           switch_pip_mirror "domestic"
           ;;
        2) switch_apt_mirror "default"
           switch_conda_mirror "default"
           switch_pip_mirror "default"
           ;;
        *) echo "Invalid selection"
           ;;
    esac
}

if [[ $EUID -eq 0 ]]; then
    echo "The current user is root"
else
    echo "The current user is not root"
    exit 1
fi
main_menu

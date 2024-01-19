#!/bin/bash

# YUM 镜像源切换
function switch_yum_mirror() {
    if [ "$1" == "domestic" ]; then
        echo "Switching to domestic YUM mirror..."
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak
        wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    else
        echo "Switching back to default YUM mirror..."
        mv -f /etc/yum.repos.d/CentOS-Base.repo_bak /etc/yum.repos.d/CentOS-Base.repo
    fi
    yum makecache
    yum -y update
}

# Conda 镜像源切换
function switch_conda_mirror() {
    if [ "$1" == "domestic" ]; then
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
    if [ "$1" == "domestic" ]; then
        echo "Switching to domestic Pip mirror..."
        mkdir -p $(dirname $pip_config_file)
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    else
        echo "Switching back to default Pip mirror..."
        pip config unset global.index-url
    fi
}

# 主菜单
function main_menu() {
    echo "1. Switch to Domestic Mirrors"
    echo "2. Switch to Default Mirrors"
    read -p "Enter your choice: " choice

    case $choice in
        1) switch_yum_mirror "domestic"
           switch_conda_mirror "domestic"
           switch_pip_mirror "domestic"
           ;;
        2) switch_yum_mirror "default"
           switch_conda_mirror "default"
           switch_pip_mirror "default"
           ;;
        *) echo "Invalid selection"
           ;;
    esac
}

main_menu

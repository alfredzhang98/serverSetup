#!/bin/bash

main_menu() {
    while true; do

        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. update apt (Face the kdump-tools and using outdated libraries problems, please run it twice if not see suuccess)\033[0m"
        echo -e "\033[32m 2. initial apt packages install(once is ok)\033[0m"
        echo -e "\033[32m 3. install Baota panel\033[0m"
        echo -e "\033[32m 4. install Baota safety monitoring\033[0m"
        echo -e "\033[32m 5. install Baota WAF\033[0m"
        echo -e "\033[32m 6. install Baota log analysis\033[0m"
        echo -e "\033[32m 7. install Baota security system\033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ******** \033[0m"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1)
            # 系统更新
            echo "Updating and upgrading system packages..."
            sudo apt-get update -y
            sudo apt-get upgrade -y
            echo "Success updating and upgrading system packages..."
            ;;
        2)
            # SSH 配置
            echo "Configuring SSH..."
            sudo sed -i 's/^.PermitRootLogin .*/PermitRootLogin yes/g' /etc/ssh/sshd_config
            sudo sed -i 's/^.PasswordAuthentication .*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            if ! grep -q "^AllowUsers root" /etc/ssh/sshd_config; then
                sudo echo "AllowUsers root" >> /etc/ssh/sshd_config
            fi
            if ! grep -q "^AllowUsers ubuntu" /etc/ssh/sshd_config; then
                sudo echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
            fi
            sudo systemctl restart sshd.service
            sudo systemctl enable sshd.service

            # 安装并配置 Fail2Ban
            echo "Installing Fail2Ban..."
            sudo apt-get install -y fail2ban
            sudo systemctl enable fail2ban
            sudo systemctl start fail2ban

            # 防火墙配置
            echo "Configuring Firewall..."
            # 检查并移除 iptables-persistent 和 netfilter-persistent
            if service netfilter-persistent status | grep -q "Active: active"; then
                sudo apt-get remove iptables-persistent netfilter-persistent -y
            fi

            # 安装 firewalld
            sudo apt-get install -y firewalld

            # 禁用 iptables ufw
            if sudo systemctl is-active --quiet iptables; then
                sudo systemctl stop iptables
                sudo systemctl disable iptables
            fi
            if sudo ufw status | grep -q "Status: active"; then
                sudo ufw disable
            fi
            # 启动并启用 firewalld
            sudo systemctl start firewalld
            sudo systemctl enable firewalld

            # 设置基本防火墙规则（根据需要调整）
            sudo firewall-cmd --zone=public --add-service=ssh --permanent
            sudo firewall-cmd --zone=public --add-service=http --permanent
            sudo firewall-cmd --zone=public --add-service=https --permanent
            sudo firewall-cmd --reload

            # 重启 SSH 服务以应用配置更改
            sudo systemctl restart sshd.service
            sudo systemctl enable sshd.service

            echo "Initial setup completed."
            ;;
        3)
            wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh ed8484bec
            ;;
        4)
            if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_btmonitor.sh; else wget -O install_btmonitor.sh https://download.bt.cn/install/install_btmonitor.sh; fi
            bash install_btmonitor.sh
            ;;
        5)
            URL=https://download.bt.cn/cloudwaf/scripts/install_cloudwaf.sh && if [ -f /usr/bin/curl ]; then curl -sSO "$URL"; else wget -O install_cloudwaf.sh "$URL"; fi
            bash install_cloudwaf.sh
            ;;
        6)
            curl -sSO http://download.bt.cn/btlogs/btlogs.sh && bash btlogs.sh install
            ;;
        7) 
            URL=https://download.bt.cn/bthids/scripts/install_hids.sh && if [ -f /usr/bin/curl ];then curl -sSO "$URL" ;else wget -O install_hids.sh "$URL"; fi
            bash install_hids.sh
            ;;
        0)
            echo "Exiting the script"
            exit 0
            ;;
        *)
            echo "Invalid selection"
            ;;
        esac
    done
}

main_menu

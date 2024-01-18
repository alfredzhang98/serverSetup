#!/bin/bash

main_menu() {
    while true; do

        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. update yum\033[0m"
        echo -e "\033[32m 2. initial install yum packages (once is ok)\033[0m"
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
            echo "Updating system packages..."
            yum -y update
            echo "Success updating system packages"
            ;;
        2)
            # SSH 配置
            echo "Configuring SSH..."
            sudo sed -i 's/^.PermitRootLogin .*/PermitRootLogin yes/g' /etc/ssh/sshd_config
            sudo sed -i 's/^.PasswordAuthentication .*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            if ! grep -q "^AllowUsers root" /etc/ssh/sshd_config; then
                echo "AllowUsers root" >> /etc/ssh/sshd_config
            fi
            sudo systemctl restart sshd.service
            sudo systemctl enable sshd.service

            # 自动更新工具安装与配置
            echo "Installing and configuring yum-cron for automatic updates..."
            yum -y install yum-cron
            sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
            systemctl start yum-cron
            systemctl enable yum-cron

            # 防火墙配置
            echo "Configuring Firewall..."
            if systemctl is-active --quiet iptables; then
                systemctl stop iptables
                systemctl disable iptables
            fi
            yum -y install firewalld
            systemctl start firewalld
            systemctl enable firewalld

            # 设置基本防火墙规则
            firewall-cmd --zone=public --add-service=ssh --permanent
            firewall-cmd --reload

            # 安装并配置 Fail2Ban
            echo "Installing Fail2Ban..."
            yum -y install fail2ban
            systemctl start fail2ban
            systemctl enable fail2ban

            echo "Initial setup completed."
            ;;
        3)
            yum install -y wget && wget -O install.sh https://download.bt.cn/install/install_6.0.sh && sh install.sh ed8484bec
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

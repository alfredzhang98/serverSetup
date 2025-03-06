#!/bin/bash

main_menu() {
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. set sudo passwd\033[0m"
        echo -e "\033[32m 2. update yum\033[0m"
        echo -e "\033[32m 3. initial install yum packages (once is ok)\033[0m"
        echo -e "\033[32m 4. install Baota panel\033[0m"
        echo -e "\033[32m 5. install Baota safety monitoring\033[0m"
        echo -e "\033[32m 6. install Baota WAF\033[0m"
        echo -e "\033[32m 7. install Baota log analysis\033[0m"
        echo -e "\033[32m 8. install Baota security system\033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ******** \033[0m"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1)  sudo passwd root
            ;;
        2)            
            # system update
            echo "Updating system packages..."
            yum -y update
            echo "Success updating system packages"
            ;;
        3)
            # ssh
            yum -y install ssh
            # yum-cron
            yum -y install yum-cron
            sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
            systemctl start yum-cron
            systemctl enable yum-cron
            # firewall
            yum -y install firewalld
            # fail2Ban
            yum -y install fail2ban
            systemctl disable fail2ban
            systemctl stop fail2ban
            # default firewalld config
            init_firewall
            # default ssh config
            init_ssh
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
            exit 1
            ;;
        *)
            echo "Invalid selection"
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

source ./function/function_ssh.sh
source ./function/function_firewall.sh
main_menu

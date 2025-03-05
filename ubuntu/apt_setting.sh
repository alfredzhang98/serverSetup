#!/bin/bash

main_menu() {
    echo -e "\033[32m Makesure we have su permission \033[0m"
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. set sudo passwd\033[0m"
        echo -e "\033[32m 2. update apt (facing kdump-tools configs and restart new packages configs)\033[0m"
        echo -e "\033[32m 3. initial apt packages install(once is ok)\033[0m"
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
            echo "Checking for unconfigured packages..."
            if dpkg -l | grep '^iU' >/dev/null 2>&1; then
                echo "Unconfigured packages found, running dpkg --configure -a..."
                sudo dpkg --configure -a
            else
                echo "No unconfigured packages found, skipping dpkg configuration."
            fi
            sudo dpkg --configure -a
            # system update and upgrade
            echo "This shell should run twice to check update and upgrade finish"
            read -p "Press Enter to continue..."
            echo "Updating system packages..."
            sudo apt-get update -y
            echo "Upgrading system packages"
            sudo apt-get upgrade -y
            echo "Success updating and upgrading system packages..."
            ;;
        3)
            # ssh
            sudo apt-get install ssh -y
            # firewall
            sudo apt-get install -y firewalld
            # fail2Ban
            sudo apt-get install -y fail2ban
            sudo systemctl disable fail2ban
            sudo systemctl stop fail2ban
            # default firewalld config
            init_firewall
            # default ssh config
            init_ssh
            echo "Initial setup completed."
            ;;
        4)
            wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && sudo bash install.sh ed8484bec
            ;;
        5)
            if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_btmonitor.sh; else wget -O install_btmonitor.sh https://download.bt.cn/install/install_btmonitor.sh; fi
            bash install_btmonitor.sh
            ;;
        6)
            URL=https://download.bt.cn/cloudwaf/scripts/install_cloudwaf.sh && if [ -f /usr/bin/curl ]; then curl -sSO "$URL"; else wget -O install_cloudwaf.sh "$URL"; fi
            bash install_cloudwaf.sh
            ;;
        7)
            curl -sSO http://download.bt.cn/btlogs/btlogs.sh && bash btlogs.sh install
            ;;
        8) 
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
        read -p "Press Enter to continue..."
    done
}

if [[ $EUID -eq 0 ]]; then
    echo "The current user is root"
else
    echo "The current user is not root"
    exit 1
fi
source ./function/function_ssh.sh
source ./function/function_firewall.sh
main_menu

#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

main_menu() {
    while true; do
        echo -e "${GREEN}******** APT-Based System Maintenance Menu ********${RESET}"
        echo -e "${GREEN} Please select an operation to perform: ${RESET}"
        echo -e "${GREEN} 1.  Set Sudo Password${RESET}"
        echo -e "${GREEN} 2.  Update APT (Handling kdump-tools Configs and Restart New Packages Configs)${RESET}"
        echo -e "${GREEN} 3.  Initial APT Packages Install (Once is OK)${RESET}"
        echo -e "${GREEN}******************************************${RESET}"
        echo -e "${GREEN} 4.  Install Baota Panel${RESET}"
        echo -e "${GREEN} 5.  Install Baota Safety Monitoring${RESET}"
        echo -e "${GREEN} 6.  Install Baota WAF${RESET}"
        echo -e "${GREEN} 7.  Install Baota Log Analysis${RESET}"
        echo -e "${GREEN} 8.  Install Baota Security System${RESET}"
        echo -e "${GREEN}******************************************${RESET}"
        echo -e "${GREEN} 0.  Exit${RESET}"
        echo -e "${GREEN}******************************************${RESET}"

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
            exit 1
            ;;
        *)
            echo "Invalid selection"
            ;;
        esac
        read -p "Press Enter to continue..."
    done
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

FUNCTION_SSH="./function/function_ssh.sh"
if [[ ! -f "$FUNCTION_SSH" ]]; then
    echo -e "${RED}Error: function_ssh.sh not found!${RESET}"
    read -rp "Do you want to continue without it? (y/N): " choice
    case $choice in
        [Yy]* ) echo -e "${YELLOW}Continuing without function_ssh.sh...${RESET}" ;;
        * ) echo "Exiting script."; exec bash; exit 1 ;;
    esac
else
    source "$FUNCTION_SSH"
fi

FUNCTION_FIREWALL="./function/function_firewall.sh"
if [[ ! -f "$FUNCTION_FIREWALL" ]]; then
    echo -e "${RED}Error: function_firewall.sh not found!${RESET}"
    read -rp "Do you want to continue without it? (y/N): " choice
    case $choice in
        [Yy]* ) echo -e "${YELLOW}Continuing without function_firewall.sh...${RESET}" ;;
        * ) echo "Exiting script."; exec bash; exit 1 ;;
    esac
else
    source "$FUNCTION_FIREWALL"
fi

main_menu

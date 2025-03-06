#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

main_menu() {
    while true; do
        echo -e "${GREEN}******** YUM-Based System Maintenance Menu ********${RESET}"
        echo -e "${GREEN} Please select an operation to perform: ${RESET}"
        echo -e "${GREEN} 1.  Set Sudo Password${RESET}"
        echo -e "${GREEN} 2.  Update YUM${RESET}"
        echo -e "${GREEN} 3.  Initial Install YUM Packages (Once is OK)${RESET}"
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

FUNCTION_SSHD="./function/function_sshd.sh"
if [[ ! -f "$FUNCTION_SSHD" ]]; then
    echo -e "${RED}Error: function_sshd.sh not found!${RESET}"
    read -rp "Do you want to continue without it? (y/N): " choice
    case $choice in
        [Yy]* ) echo -e "${YELLOW}Continuing without function_sshd.sh...${RESET}" ;;
        * ) echo "Exiting script."; exit 1 ;;
    esac
else
    source "$FUNCTION_SSHD"
fi

FUNCTION_FIREWALL="./function/function_firewall.sh"
if [[ ! -f "$FUNCTION_FIREWALL" ]]; then
    echo -e "${RED}Error: function_firewall.sh not found!${RESET}"
    read -rp "Do you want to continue without it? (y/N): " choice
    case $choice in
        [Yy]* ) echo -e "${YELLOW}Continuing without function_firewall.sh...${RESET}" ;;
        * ) echo "Exiting script."; exit 1 ;;
    esac
else
    source "$FUNCTION_FIREWALL"
fi

main_menu

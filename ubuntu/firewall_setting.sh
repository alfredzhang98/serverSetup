#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

main_menu() {
    while true; do
        echo -e "${GREEN}******** Firewall Configuration Menu ********${RESET}"
        echo -e "${GREEN} Please select an operation to perform: ${RESET}"
        echo -e "${GREEN} 1.  Init Firewall${RESET}"
        echo -e "${GREEN} 2.  View Firewall Status${RESET}"
        echo -e "${GREEN} 3.  List Ports in All Zones${RESET}"
        echo -e "${GREEN} 4.  List All Available Services${RESET}"
        echo -e "${GREEN}*********************************************${RESET}"
        echo -e "${GREEN} 6.  Restart Firewall${RESET}"
        echo -e "${GREEN} 7.  Start Firewall${RESET}"
        echo -e "${GREEN} 8.  Stop Firewall${RESET}"
        echo -e "${GREEN}*********************************************${RESET}"
        echo -e "${GREEN}10.  Add a Port to a Zone${RESET}"
        echo -e "${GREEN}11.  Add a Service${RESET}"
        echo -e "${GREEN}12.  Delete a Port from a Zone${RESET}"
        echo -e "${GREEN}13.  Delete a Service${RESET}"
        echo -e "${GREEN}*********************************************${RESET}"
        echo -e "${GREEN}20.  Enable Zone Drifting${RESET}"
        echo -e "${GREEN}21.  Disable Zone Drifting${RESET}"
        echo -e "${GREEN}*********************************************${RESET}"
        echo -e "${GREEN} 0.  Exit${RESET}"
        echo -e "${GREEN}*********************************************${RESET}"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1)  
            init_firewall
            ;;
        2)
            systemctl status firewalld
            ;;
        3)
            echo "Listing ports for all zones:"
            for zone in $(firewall-cmd --get-zones); do
                echo "Zone: $zone"
                firewall-cmd --zone=$zone --list-ports
            done
            ;;
        4)
            echo "Listing all available services:"
            firewall-cmd --get-services
            ;;
        6)
            systemctl restart firewalld
            ;;
        7)
            systemctl start firewalld
            systemctl enable firewalld
            ;;
        8)
            systemctl stop firewalld
            systemctl disable firewalld
            ;;
        10)
            read -p "Enter the port number to add (e.g., 8080): " port
            read -p "Enter the protocol type (tcp/udp/icmp): " protocol
            echo "Available zones:"
            firewall-cmd --get-zones
            read -p "Enter the zone to which you want to add the port (e.g., public, docker): " zone
            firewall-cmd --zone=$zone --add-port=$port/$protocol --permanent
            firewall-cmd --reload
            echo "Ports in the $zone zone:"
            firewall-cmd --zone=$zone --list-ports
            ;;
        11)
            read -p "Enter the service name to add (e.g., http): " service
            firewall-cmd --add-service=$service --permanent
            firewall-cmd --reload
            firewall-cmd --list-services
            ;;
        12)
            read -p "Enter the port number to remove (e.g., 8080): " port
            read -p "Enter the protocol type (tcp/udp/icmp): " protocol
            echo "Available zones:"
            firewall-cmd --get-zones
            read -p "Enter the zone to which you want to remove the port (e.g., public, docker): " zone
            firewall-cmd --zone=$zone --remove-port=$port/$protocol --permanent
            firewall-cmd --reload
            firewall-cmd --zone=$zone --list-ports
            ;;
        13)
            read -p "Enter the service name to delete (e.g., http): " service
            firewall-cmd --remove-service=$service --permanent
            firewall-cmd --reload
            firewall-cmd --list-services
            ;;
        20) enable_zone_drifting ;;
        21) disable_zone_drifting ;;
        0)
            echo "Exiting the script"
            break
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

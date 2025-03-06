#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

UFW_RULES="/etc/ufw/before.rules"

function list_ports() {
    echo "Listing current UFW rules:"
    sudo ufw status numbered
}

function list_services() {
    echo "Listing available services:"
    ls /etc/services | cut -d' ' -f1
}

function manage_firewall() {
    case $1 in
        start)
            sudo ufw enable
            ;;
        stop)
            sudo ufw disable
            ;;
        restart)
            sudo ufw disable
            sudo ufw enable
            ;;
        status)
            sudo ufw status verbose
            ;;
        *)
            echo "Invalid option for manage_firewall"
            ;;
    esac
}

function modify_rule() {
    read -p "Enter the port number (e.g., 8080): " port
    read -p "Enter the protocol type (tcp/udp): " protocol
    read -p "Enter 'add' to allow or 'delete' to deny a port: " action

    if [ "$action" == "add" ]; then
        sudo ufw allow $port/$protocol
    elif [ "$action" == "delete" ]; then
        sudo ufw delete allow $port/$protocol
    else
        echo "Invalid action"
    fi
}

function add_delete_application_rule() {
    echo "Available applications:"
    sudo ufw app list
    read -p "Enter the application name (e.g., 'Apache'): " application
    read -p "Enter 'add' to allow or 'delete' to deny the application: " action

    if [ "$action" == "add" ]; then
        sudo ufw allow "$application"
    elif [ "$action" == "delete" ]; then
        sudo ufw delete allow "$application"
    else
        echo "Invalid action"
    fi
}

main_menu() {

    while true; do
        echo -e "${GREEN}******** Firewall Configuration Menu ********${RESET}"
        echo -e "${GREEN} 1.  Initialize Firewall Setup${RESET}"
        echo -e "${GREEN} 2.  View Firewall Status${RESET}"
        echo -e "${GREEN} 3.  List Ports${RESET}"
        echo -e "${GREEN} 4.  List All Available Services${RESET}"
        echo -e "${GREEN} 5.  Start Firewall${RESET}"
        echo -e "${GREEN} 6.  Stop Firewall${RESET}"
        echo -e "${GREEN} 7.  Restart Firewall${RESET}"
        echo -e "${GREEN} 8.  Add/Delete a Port Rule${RESET}"
        echo -e "${GREEN} 9.  Add/Delete an Application Rule${RESET}"
        echo -e "${GREEN}********************************************${RESET}"
        echo -e "${GREEN} 0.  Exit${RESET}"
        echo -e "${GREEN}********************************************${RESET}"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
            1)
                # Check if firewalld is active and stop it
                if systemctl is-active --quiet firewalld; then
                    echo "Stopping firewalld..."
                    sudo systemctl stop firewalld
                    # sudo systemctl status firewalld
                else
                    echo "firewalld is not running."
                fi
                sudo systemctl start ufw
                sudo systemctl enable ufw
                sudo systemctl restart ufw
                sudo ufw allow 22/tcp
                sudo ufw allow 80/tcp
                sudo ufw allow 443/tcp
                sudo ufw allow 3389/tcp
                sudo ufw allow 3389/udp
                sudo ufw enable
                sudo ufw reload
            ;;
            2) manage_firewall status ;;
            3) list_ports ;;
            4) list_services ;;
            5) manage_firewall start ;;
            6) manage_firewall stop ;;
            7) manage_firewall restart ;;
            8) modify_rule ;;
            9) add_delete_application_rule ;;
            0) echo "Exiting the script"; break ;;
            *) echo "Invalid selection" ;;
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

main_menu
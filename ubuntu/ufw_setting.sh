#!/bin/bash

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
    echo "Initializing firewall setup..."
    # You can call stop_firewalls function here if you have it

    while true; do
        echo "********"
        echo "Please select an operation to perform:"
        echo "1. Initializing firewall setup"
        echo "2. View firewall status"
        echo "3. List ports"
        echo "4. List all available services"
        echo "5. Start firewall"
        echo "6. Stop firewall"
        echo "7. Restart firewall"
        echo "8. Add/Delete a port rule"
        echo "9. Add/Delete an application rule"
        echo "0. Exit"
        echo "********"

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
            0) echo "Exiting the script"; exit 0 ;;
            *) echo "Invalid selection" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

main_menu
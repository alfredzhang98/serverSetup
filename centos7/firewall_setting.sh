#!/bin/bash

while true; do
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m Please select an operation to perform: \033[0m"
    echo -e "\033[32m 1. View firewall status and ports \033[0m"
    echo -e "\033[32m 2. Restart firewall \033[0m"
    echo -e "\033[32m 3. Start firewall \033[0m"
    echo -e "\033[32m 4. Stop firewall \033[0m"
    echo -e "\033[32m 5. Add a port to the public zone \033[0m"
    echo -e "\033[32m 6. Add a service \033[0m"
    echo -e "\033[32m 7. Deleted a port from the public zone \033[0m"
    echo -e "\033[32m 8. Deleted a service \033[0m"
    echo -e "\033[32m 0. Exit \033[0m"
    echo -e "\033[32m ******** \033[0m"

    read -p "Enter the corresponding number for the operation: " choice

    case $choice in
    1)
        systemctl status firewalld
        firewall-cmd --list-ports
        ;;
    2)
        systemctl restart firewalld
        ;;
    3)
        systemctl start firewalld
        systemctl enable firewalld
        ;;
    4)
        systemctl stop firewalld
        systemctl disable firewalld
        ;;
    5)
        read -p "Enter the port number to add: " port
        read -p "Enter the protocol type (tcp/udp/icmp): " service
        firewall-cmd --zone=public --add-port=$port/$service --permanent
        firewall-cmd --reload
        firewall-cmd --list-ports
        ;;
    6)
        read -p "Enter the service name to add: " service
        firewall-cmd --add-service=$service --permanent
        firewall-cmd --reload
        firewall-cmd --list-services
        ;;
    7)
        read -p "Enter the port/service to remove: " portService
        firewall-cmd --zone=public --remove-port=$portService
        firewall-cmd --reload
        firewall-cmd --list-ports
        ;;
    8)
        read -p "Enter the service name to add: " service
        firewall-cmd --remove-service=$service --permanent
        firewall-cmd --reload
        firewall-cmd --list-services
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

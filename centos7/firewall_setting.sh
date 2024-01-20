#!/bin/bash

function enable_zone_drifting() {
    echo "Enabling Zone Drifting in firewalld..."
    sed -i 's/AllowZoneDrifting=no/AllowZoneDrifting=yes/' /etc/firewalld/firewalld.conf
    systemctl restart firewalld
    echo "Zone Drifting enabled."
}


function disable_zone_drifting() {
    echo "Disabling Zone Drifting in firewalld..."
    firewall-cmd --set-log-denied=all
    sed -i 's/AllowZoneDrifting=yes/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf
    systemctl restart firewalld
    echo "Zone Drifting disabled."
}

main_menu() {
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. Init firewall \033[0m"
        echo -e "\033[32m 2. View firewall status \033[0m"
        echo -e "\033[32m 3. List ports in all zones \033[0m"
        echo -e "\033[32m 4. List all available services \033[0m"
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m 6. Restart firewall \033[0m"
        echo -e "\033[32m 7. Start firewall \033[0m"
        echo -e "\033[32m 8. Stop firewall \033[0m"
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m 10. Add a port to a zone \033[0m"
        echo -e "\033[32m 11. Add a service \033[0m"
        echo -e "\033[32m 12. Delete a port from a zone \033[0m"
        echo -e "\033[32m 13. Delete a service \033[0m"
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m 20. Ensable zone drifting \033[0m"
        echo -e "\033[32m 21. Disable zone drifting \033[0m"
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ******** \033[0m"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1)  
            sudo systemctl start firewalld
            sudo systemctl enable firewalld
            sudo firewall-cmd --zone=public --add-service=ssh --permanent
            sudo firewall-cmd --zone=public --add-service=http --permanent
            sudo firewall-cmd --zone=public --add-service=https --permanent
            sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
            sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
            sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
            sudo firewall-cmd --zone=public --add-port=3389/udp --permanent
            sudo firewall-cmd --zone=public --add-port=3389/tcp --permanent
            sudo firewall-cmd --reload
            sudo systemctl restart firewalld
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
            exit 0
            ;;
        *)
            echo "Invalid selection"
            ;;
        esac
        read -p "Press Enter to continue..."
    done
}

main_menu

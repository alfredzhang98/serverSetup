#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

function dpkg_error() {
    echo "This is fixing Sub-process /usr/bin/dpkg returned an error code problem"
    sudo mv /var/lib/dpkg/info /var/lib/dpkg/info.bk
    sudo mkdir /var/lib/dpkg/info
    sudo apt-get update -y
    sudo apt-get install -f
    sudo mv /var/lib/dpkg/info/* /var/lib/dpkg/info.bk
    sudo rm -rf /var/lib/dpkg/info
    sudo mv /var/lib/dpkg/info.bk /var/lib/dpkg/info
}

# Main menu function
main_menu() {
  while true; do
    echo -e "${GREEN}******** System Fix Menu ************${RESET}"
    echo -e "${GREEN} 1.  Fix 'E: Sub-process /usr/bin/dpkg returned an error code (1)'${RESET}"
    echo -e "${GREEN}*************************************${RESET}"
    echo -e "${GREEN} 0.  Exit${RESET}"
    echo -e "${GREEN}*************************************${RESET}"

    case $selection in
    1) dpkg_error ;;
    0) break ;;
    *) echo "Invalid selection." ;;
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

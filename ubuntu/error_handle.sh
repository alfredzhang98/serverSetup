

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
  echo -e "\033[32m Makesure we have su permission \033[0m"
  while true; do
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m1. Fix E: Sub-process /usr/bin/dpkg returned an error code (1)\033[0m"
    echo -e "\033[32m ******** \033[0m"
    case $selection in
    1) dpkg_error ;;
    0) break ;;
    *) echo "Invalid selection." ;;
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
main_menu

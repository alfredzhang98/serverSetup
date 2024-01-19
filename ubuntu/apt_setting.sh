#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

function user_exists() {
  local username=$1
  getent passwd "$username" >/dev/null 2>&1
}

function enable_and_start_ssh() {
  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
}

function modify_ssh_config() {
    local config_name="$1"
    local default_choice="$2"
    local choice="$3"
    if grep -q "^#$config_name" "$SSH_CONFIG_FILE"; then
        sudo sed -i "s/^#$config_name.*/#$config_name $default_choice/" "$SSH_CONFIG_FILE"
        if ! grep -q "^$config_name" "$SSH_CONFIG_FILE"; then
            sudo sed -i "/^#$config_name/a $config_name $choice" "$SSH_CONFIG_FILE"
        fi
    else
        echo "#$config_name $default_choice" | sudo tee -a "$SSH_CONFIG_FILE"
        echo "$config_name $choice" | sudo tee -a "$SSH_CONFIG_FILE"
    fi
    if grep -q "^$config_name" "$SSH_CONFIG_FILE"; then
        sudo sed -i "s/^$config_name.*/$config_name $choice/" "$SSH_CONFIG_FILE"
    fi
}

function set_user_permission() {
    local username="$1"

    if [ -z "$username" ]; then
        read -p "Enter username: " username
    fi

    if ! user_exists "$username"; then
        echo "User $username does not exist."
        return
    fi

    if grep -q "^AllowUsers" "$SSH_CONFIG_FILE"; then
        if grep -q "AllowUsers.*$username" "$SSH_CONFIG_FILE"; then
            echo "User $username is already allowed in SSH config."
        else
            sudo sed -i "/^AllowUsers/s/$/ $username/" "$SSH_CONFIG_FILE"
            echo "User $username added to AllowUsers in SSH config."
        fi
    else
        echo "AllowUsers $username" | sudo tee -a "$SSH_CONFIG_FILE"
        echo "AllowUsers with user $username added to SSH config."
    fi

    sudo systemctl restart sshd.service
}

main_menu() {
    echo -e "\033[32m Makesure we have su permission \033[0m"
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. update apt (facing kdump-tools configs and restart new packages configs)\033[0m"
        echo -e "\033[32m 2. set sudo passwd\033[0m"
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
        1)
            # 系统更新
            echo "This shell should run twice to check update and upgrade finish"
            read -p "Press Enter to continue..."
            echo "Updating system packages..."
            sudo apt-get update -y
            echo "Upgrading system packages"
            sudo apt-get upgrade -y
            echo "Success updating and upgrading system packages..."
            ;;
        2)  sudo passwd root
            ;;
        3)
            # ssh
            echo "Configuring SSH..."
            sudo apt-get install ssh -y

            # fail2Ban
            echo "Installing Fail2Ban..."
            sudo apt-get install -y fail2ban
            sudo systemctl enable fail2ban
            sudo systemctl start fail2ban

            # firewall
            echo "Configuring Firewall..."
            sudo apt-get install -y firewalld nftables ufw
            sudo systemctl stop firewalld

            # ssh
            enable_and_start_ssh
            modify_ssh_config "PermitRootLogin" "prohibit-password" "yes"
            modify_ssh_config "PubkeyAuthentication" "yes" "yes"
            modify_ssh_config "PasswordAuthentication" "no" "yes"
            modify_ssh_config "PermitEmptyPasswords" "no" "no"
            set_user_permission "root"
            set_user_permission "ubuntu"

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

main_menu

#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

function user_exists() {
  local username=$1
  getent passwd "$username" >/dev/null 2>&1
}

function add_host_keys(){
    host_keys=(
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_dsa_key"
    "/etc/ssh/ssh_host_ecdsa_key"
    "/etc/ssh/ssh_host_ed25519_key"
  )
  # Check if the sshd_config file exists
  if [[ -f "$SSH_CONFIG_FILE" ]]; then
    # Check if the host key entries already exist in the sshd_config file
    if grep -Fxq "HostKey ${host_keys[0]}" $SSH_CONFIG_FILE; then
      echo "HostKey entries already exist in sshd_config. No changes needed."
    else
      # Append the host key entries to the sshd_config file
      for key_file in "${host_keys[@]}"; do
        echo "HostKey $key_file" | sudo tee -a $SSH_CONFIG_FILE > /dev/null
      done
      echo "HostKey entries added to sshd_config."
    fi
  else
    echo "sshd_config file not found."
  fi
}

function enable_and_start_ssh() {
  systemctl enable sshd.service
  systemctl start sshd.service
}

function modify_ssh_config() {
    local config_name="$1"
    local default_choice="$2"
    local choice="$3"
    if grep -q "^#$config_name" "$SSH_CONFIG_FILE"; then
        sed -i "s/^#$config_name.*/#$config_name $default_choice/" "$SSH_CONFIG_FILE"
        if ! grep -q "^$config_name" "$SSH_CONFIG_FILE"; then
            sed -i "/^#$config_name/a $config_name $choice" "$SSH_CONFIG_FILE"
        fi
    else
        echo "#$config_name $default_choice" >> "$SSH_CONFIG_FILE"
        echo "$config_name $choice" >> "$SSH_CONFIG_FILE"
    fi
    if grep -q "^$config_name" "$SSH_CONFIG_FILE"; then
        sed -i "s/^$config_name.*/$config_name $choice/" "$SSH_CONFIG_FILE"
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
            sed -i "/^AllowUsers/s/$/ $username/" "$SSH_CONFIG_FILE"
            echo "User $username added to AllowUsers in SSH config."
        fi
    else
        echo -e "\nAllowUsers $username" >> "$SSH_CONFIG_FILE"
        echo "AllowUsers with user $username added to SSH config."
    fi
    systemctl restart sshd.service
}

main_menu() {
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. set sudo passwd\033[0m"
        echo -e "\033[32m 2. update yum\033[0m"
        echo -e "\033[32m 3. initial install yum packages (once is ok)\033[0m"
        echo -e "\033[32m 4. install Baota panel\033[0m"
        echo -e "\033[32m 5. install Baota safety monitoring\033[0m"
        echo -e "\033[32m 6. install Baota WAF\033[0m"
        echo -e "\033[32m 7. install Baota log analysis\033[0m"
        echo -e "\033[32m 8. install Baota security system\033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ******** \033[0m"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1)  sudo passwd root
            ;;
        2)
            # 系统更新
            echo "Updating system packages..."
            yum -y update
            echo "Success updating system packages"
            ;;
        3)
            # ssh
            echo "Configuring SSH..."
            yum -y install ssh
            # yum-cron
            echo "Installing and configuring yum-cron for automatic updates..."
            yum -y install yum-cron
            sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
            systemctl start yum-cron
            systemctl enable yum-cron
            # firewall
            yum -y install firewalld
            # fail2Ban
            echo "Installing Fail2Ban..."
            yum -y install fail2ban
            systemctl disable fail2ban
            systemctl stop fail2ban
            # default use the firewalld
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
            # ssh
            enable_and_start_ssh
            add_host_keys
            modify_ssh_config "PermitRootLogin" "prohibit-password" "yes"
            modify_ssh_config "PubkeyAuthentication" "yes" "yes"
            modify_ssh_config "PasswordAuthentication" "yes" "yes"
            modify_ssh_config "PermitEmptyPasswords" "no" "no"
            set_user_permission "root"
            systemctl restart sshd.service
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

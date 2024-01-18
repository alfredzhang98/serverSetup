#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

function user_exists() {
  local username=\$1
  id "$username" >/dev/null 2>&1
}

function confirm_operation() {
    read -p "Are you sure you want to continue? [y/N]: " confirmation
    case $confirmation in
        [Yy]*) return 0 ;;
        *) echo "Operation cancelled"; return 1 ;;
    esac
}

# Function to display key SSH configurations
function view_ssh_config() {
  echo "SSH Settings:"

  # Function to display a specific configuration
  display_config() {
    local config_key=$1
    local config_value=$(grep "^$config_key" "$SSH_CONFIG_FILE" | tail -1 | awk '{print $2}')
    if [ -z "$config_value" ]; then
      config_value="Not Set/Commented Out"
    fi
    echo "$config_key: $config_value"
  }

  # List of key configurations to display
  display_config "Port"
  display_config "PubkeyAuthentication"
  display_config "PasswordAuthentication"
  display_config "PermitRootLogin"
  display_config "PermitEmptyPasswords"
  display_config "ClientAliveInterval"
  display_config "ClientAliveCountMax"
  display_config "AllowTcpForwarding"
  display_config "X11Forwarding"
}

function vim_change_sshd_config() {
  sudo vim "$SSH_CONFIG_FILE"
  systemctl restart sshd
}

# Function to change SSH port
function change_ssh_port() {
    read -p "Enter new SSH port: " new_port

    # Check that the port number is in the valid range
    if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
        # Find the existing Port configuration and replace it with the new port number
        if grep -q "^Port " "$SSH_CONFIG_FILE"; then
            sed -i "s/^Port .*/Port $new_port/" "$SSH_CONFIG_FILE"
        else
            echo "Port $new_port" >> "$SSH_CONFIG_FILE"
        fi
        echo "SSH port changed to $new_port"
        systemctl restart sshd
    else
        echo "Invalid port. Please enter a number between 1 and 65535."
    fi
}

# Function to toggle PermitRootLogin
function toggle_permit_root_login() {
  echo "Current PermitRootLogin setting:"
  grep "^PermitRootLogin" "$SSH_CONFIG_FILE"
  
  read -p "Set PermitRootLogin (yes/no/prohibit-password): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" || "$choice" == "prohibit-password" ]]; then
    sed -i "s/^#PermitRootLogin.*/PermitRootLogin prohibit-password/" "$SSH_CONFIG_FILE"
    sed -i "s/^PermitRootLogin.*/PermitRootLogin $choice/" "$SSH_CONFIG_FILE"
    echo "PermitRootLogin set to $choice"
  else
    echo "Invalid input. Please enter 'yes', 'no', or 'prohibit-password'."
  fi
  systemctl restart sshd
}

# Toggle Public Key Authentication
function toggle_pubkey_authentication() {
  read -p "Enable Pubkey Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication no/" "$SSH_CONFIG_FILE"
    sed -i "s/^PubkeyAuthentication.*/PubkeyAuthentication $choice/" "$SSH_CONFIG_FILE"
    echo "Pubkey Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  systemctl restart sshd
}

# Function to enable or disable password authentication
function toggle_password_authentication() {
  read -p "Enable Password Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication yes/" "$SSH_CONFIG_FILE"
    sed -i "s/^PasswordAuthentication.*/PasswordAuthentication $choice/" "$SSH_CONFIG_FILE"
    echo "Password Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  systemctl restart sshd
}

# Function to backup the SSH configuration file
function backup_ssh_config() {
    local backup_file="$SSH_CONFIG_FILE-$(date +%F-%H%M%S)"
    if cp "$SSH_CONFIG_FILE" "$backup_file"; then
        echo "Backup created: $backup_file"
    else
        echo "Error: Failed to create backup of SSH config."
        return 1
    fi
}

# Function to restore the SSH configuration file from a backup
function restore_ssh_config() {
    echo "Available backups:"
    ls -l $SSH_CONFIG_FILE-*
    read -p "Enter the backup file to restore (full path): " backup_file
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$SSH_CONFIG_FILE"
        echo "Configuration restored from $backup_file"
        systemctl restart sshd
    else
        echo "Backup file not found."
    fi
}

function enable_and_start_ssh() {
  systemctl enable sshd
  systemctl start sshd
  systemctl status sshd
}

function reinstall_ssh() {
  echo "Reinstalling SSH..."
  confirm_operation || return
  if apt remove -y openssh-server && apt install -y openssh-server; then
    enable_and_start_ssh
    echo "SSH reinstalled and service restarted."
  else
    echo "Error occurred during SSH reinstallation."
  fi
}

function root_path_check() {
    if [ ! -d "/root/.ssh" ]; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
    fi
    if [ ! -f "/root/.ssh/authorized_keys" ]; then
        touch /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    fi
}

function edit_root_authorized_keys() {
    root_path_check
    vim /root/.ssh/authorized_keys
}

function reset_root_authorized_keys() {
    if confirm_operation; then
        root_path_check
        if [ -f "/root/.ssh/authorized_keys" ]; then
            rm /root/.ssh/authorized_keys
        fi
        mkdir -p /root/.ssh
        touch /root/.ssh/authorized_keys
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/authorized_keys
        echo "authorized_keys file reset and permissions set, please put in your public keys in this file"
        systemctl restart sshd
    else
        echo "Operation cancelled."
    fi
}

function set_user_permission() {
    read -p "Enter username: " username
    if ! user_exists "$username"; then
        echo "User $username does not exist."
        return
    fi
    if grep -q "^AllowUsers" "$SSH_CONFIG_FILE"; then
        if grep "AllowUsers.*$username" "$SSH_CONFIG_FILE" > /dev/null; then
            echo "User $username is already allowed in SSH config."
        else
            sed -i "/^AllowUsers/s/$/ $username/" "$SSH_CONFIG_FILE"
            echo "User $username added to AllowUsers in SSH config."
        fi
    else
        echo "AllowUsers $username" >> "$SSH_CONFIG_FILE"
        echo "AllowUsers with user $username added to SSH config."
    fi

    systemctl restart sshd
}

function get_user_group() {
    local username=\$1
    group=$(id -gn "$username")
    echo "$group"
}

function user_path_check() {
    local username=\$1
    group=$(get_user_group "$username")
    if [ ! -d "/home/$username/.ssh" ]; then
        mkdir -p /home/$username/.ssh
        chown "$username:$group" "/home/$username/.ssh"
        chmod 700 /home/$username/.ssh
    fi
    if [ ! -f "/home/$username/.ssh/authorized_keys" ]; then
        touch /home/$username/.ssh/authorized_keys
        chown "$username:$group" "/home/$username/.ssh/authorized_keys"
        chmod 600 /home/$username/.ssh/authorized_keys
    fi
}

function edit_user_authorized_keys() {
    read -p "Enter username: " username
    if ! user_exists "$username"; then
      echo "User $username does not exist."
      return
    fi
    user_path_check "$username"
    vim /home/$username/.ssh/authorized_keys
}

function update_user_authorized_keys() {
  echo "Users existing authorized_keys files will be overwritten by root one"
  confirm_operation || return
  read -p "Enter username: " username
  if ! user_exists "$username"; then
    echo "User $username does not exist."
    return
  fi
  user_path_check "$username"
  cat /root/.ssh/authorized_keys > /home/$username/.ssh/authorized_keys
}

function generate_ssh_keys() {
    if [ ! -d "/root/.ssh" ]; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
    fi
    if [ ! -f "/root/.ssh/authorized_keys" ]; then
        touch /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    fi
    ssh-keygen -t rsa -b 4096 -N '' -f /tmp/tempkey
    public_key=$(cat /tmp/tempkey.pub)
    echo "$public_key" >> /root/.ssh/authorized_keys
    echo "Generated private key:"
    cat /tmp/tempkey
    rm /tmp/tempkey.pub
    rm /tmp/tempkey
    read -p "Please keep your key carefully. Press Enter to continue..."
    clear
}

# Main menu function
main_menu() {
  while true; do
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m1. View SSH Configuration\033[0m"
    echo -e "\033[32m2. Change SSH Configs by vim\033[0m"
    echo -e "\033[32m3. Change SSH Port\033[0m"
    echo -e "\033[32m4. Toggle PermitRootLogin\033[0m"
    echo -e "\033[32m5. Toggle Public Key Authentication\033[0m"
    echo -e "\033[32m6. Toggle Password Authentication\033[0m"
    echo -e "\033[32m7. Backup SSH Configuration\033[0m"
    echo -e "\033[32m8. Restore SSH Configuration\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m10. Reinstall SSH\033[0m"
    echo -e "\033[32m11. Status SSH Service\033[0m"
    echo -e "\033[32m12. Enable and Start SSH Service\033[0m"
    echo -e "\033[32m13. Restart SSH Service\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m20. Edit root authorized_keys\033[0m"
    echo -e "\033[32m21. Reset root authorized_keys\033[0m"
    echo -e "\033[32m22. Set user permission to sshd.conifg file\033[0m"
    echo -e "\033[32m23. Edit user authorized_keys\033[0m"
    echo -e "\033[32m24. Update user authorized_keys\033[0m"
    echo -e "\033[32m25. Generate ssh key pairs\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m0. Quit\033[0m"
    read -p "Enter selection: " selection
    echo -e "\033[32m ******** \033[0m"

    case $selection in
    1) view_ssh_config ;;
    2) vim_change_sshd_config;;
    3) change_ssh_port ;;
    4) toggle_permit_root_login ;;
    5) toggle_pubkey_authentication ;;
    6) toggle_password_authentication ;;
    7) backup_ssh_config ;;
    8) restore_ssh_config ;;

    10) reinstall_ssh ;;
    11) systemctl status sshd ;;
    12) enable_and_start_ssh ;;
    13) systemctl restart sshd ;;

    20) edit_root_authorized_keys ;;
    21) reset_root_authorized_keys ;;
    22) set_user_permission ;;
    23) edit_user_authorized_keys ;;
    24) update_user_authorized_keys ;;
    25) generate_ssh_keys;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}

main_menu

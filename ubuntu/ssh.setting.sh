#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

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
  restart_ssh_service
}

# Function to change SSH port
function change_ssh_port() {
  read -p "Enter new SSH port: " new_port
  if [[ "$new_port" =~ ^[0-9]+$ ]]; then
    sed -i "s/^#Port.*/Port $new_port/" "$SSH_CONFIG_FILE"
    sed -i "s/^Port.*/Port $new_port/" "$SSH_CONFIG_FILE"
    echo "SSH port changed to $new_port"
  else
    echo "Invalid port. Please enter a number."
  fi
  restart_ssh_service
}

# Toggle Public Key Authentication
function toggle_pubkey_authentication() {
  read -p "Enable Pubkey Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication $choice/" "$SSH_CONFIG_FILE"
    sed -i "s/^PubkeyAuthentication.*/PubkeyAuthentication $choice/" "$SSH_CONFIG_FILE"
    echo "Pubkey Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  restart_ssh_service
}

# Function to enable or disable password authentication
function toggle_password_authentication() {
  read -p "Enable Password Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication $choice/" "$SSH_CONFIG_FILE"
    sed -i "s/^PasswordAuthentication.*/PasswordAuthentication $choice/" "$SSH_CONFIG_FILE"
    echo "Password Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  restart_ssh_service
}

# Function to backup the SSH configuration file
function backup_ssh_config() {
  local backup_file="$SSH_CONFIG_FILE-$(date +%F-%H%M%S)"
  cp "$SSH_CONFIG_FILE" "$backup_file"
  echo "Backup created: $backup_file"
}

# Function to restore the SSH configuration file from a backup
function restore_ssh_config() {
    echo "Available backups:"
    ls -l $SSH_CONFIG_FILE-*
    read -p "Enter the backup file to restore (full path): " backup_file
    if [ -f "$backup_file" ]; then
        cp "$backup_file" "$SSH_CONFIG_FILE"
        echo "Configuration restored from $backup_file"
        restart_ssh_service
    else
        echo "Backup file not found."
    fi
}


function status_ssh() {
  systemctl status sshd.service
}

function enable_and_start_ssh() {
  systemctl enable sshd.service
  systemctl start sshd.service
  systemctl status sshd.service
}

# Function to restart SSH service
function restart_ssh_service() {
  systemctl restart sshd.service
  systemctl status sshd.service
}

function reinstall_ssh() {
  echo "Reinstalling SSH..."
  confirm_operation || return
  if sudo apt-get remove --purge -y openssh-server && sudo apt-get install -y openssh-server; then
    enable_and_start_ssh
    echo "SSH reinstalled and service restarted."
  else
    echo "Error occurred during SSH reinstallation."
  fi
}

function reset_authorized_keys() {
  confirm_operation || return
  mkdir -p /root/.ssh
  > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
  echo "authorized_keys file reset and permissions set, please put in your public keys in this files"
  restart_ssh_service
}

# Main menu function
main_menu() {
  while true; do
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m1. View SSH Configuration\033[0m"
    echo -e "\033[32m2. Change SSH Configs by vim\033[0m"
    echo -e "\033[32m3. Change SSH Port\033[0m"
    echo -e "\033[32m4. Toggle Public Key Authentication\033[0m"
    echo -e "\033[32m5. Toggle Password Authentication\033[0m"
    echo -e "\033[32m6. Backup SSH Configuration\033[0m"
    echo -e "\033[32m7. Restore SSH Configuration\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m10. Status SSH Service\033[0m"
    echo -e "\033[32m11. Enable and Start SSH Service\033[0m"
    echo -e "\033[32m12. Restart SSH Service\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m20. Reinstall SSH\033[0m"
    echo -e "\033[32m21. Reset /root/.ssh/authorized_keys\033[0m"
    echo -e "\033[32m ******** \033[0m"
    echo -e "\033[32m0. Quit\033[0m"
    read -p "Enter selection: " selection
    echo -e "\033[32m ******** \033[0m"

    case $selection in
    1) view_ssh_config ;;
    2) vim_change_sshd_config;;
    3) change_ssh_port ;;
    4) toggle_pubkey_authentication ;;
    5) toggle_password_authentication ;;
    6) backup_ssh_config ;;
    7) restore_ssh_config ;;

    10) status_ssh ;;
    11) enable_and_start_ssh ;;
    12) restart_ssh_service ;;
    20) reinstall_ssh ;;
    21) reset_authorized_keys ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}

main_menu

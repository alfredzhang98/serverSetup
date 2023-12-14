#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

# Function to display key SSH configurations
function view_ssh_config() {
  echo "Key SSH Configuration Settings:"

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
  display_config "PermitRootLogin"
  display_config "PasswordAuthentication"
  display_config "ChallengeResponseAuthentication"
  display_config "UsePAM"
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
}

# Function to backup the SSH configuration file
function backup_ssh_config() {
  local backup_file="$SSH_CONFIG_FILE-$(date +%F-%H%M%S)"
  cp "$SSH_CONFIG_FILE" "$backup_file"
  echo "Backup created: $backup_file"
}

# Function to restart SSH service
function restart_ssh_service() {
  systemctl restart sshd.service
  echo "SSH service restarted."
}

# Main menu function
main_menu() {
  while true; do
    echo -e "\033[32m1. View SSH Configuration\033[0m"
    echo -e "\033[32m2. Toggle Password Authentication\033[0m"
    echo -e "\033[32m3. Change SSH Port\033[0m"
    echo -e "\033[32m4. Backup SSH Configuration\033[0m"
    echo -e "\033[32m5. Restart SSH Service\033[0m"
    echo -e "\033[32m0. Quit\033[0m"
    read -p "Enter selection: " selection

    case $selection in
    1) view_ssh_config ;;
    2) toggle_password_authentication ;;
    3) change_ssh_port ;;
    4) backup_ssh_config ;;
    5) restart_ssh_service ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}

main_menu

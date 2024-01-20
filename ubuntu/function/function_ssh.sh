#!/bin/bash

SSH_CONFIG_FILE="/etc/ssh/sshd_config"

function _user_exists() {
  local username="$1"
  getent passwd "$username" >/dev/null 2>&1
}

function _confirm_operation() {
  read -p "Are you sure you want to continue? [y/N]: " confirmation
  case $confirmation in
      [Yy]*) return 0 ;;
      *) echo "Operation cancelled"; return 1 ;;
  esac
}

function _enable_and_start_ssh() {
  sudo systemctl enable sshd.service
  sudo systemctl start sshd.service
}

function _add_host_keys(){
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

# Function to display a specific configuration
function _display_config() {
  local config_key=$1
  local config_value=$(grep "^$config_key" "$SSH_CONFIG_FILE" | tail -1 | awk '{print $2}')
  if [ -z "$config_value" ]; then
      config_value="Not Set/Commented Out"
  fi
  echo "$config_key: $config_value"
}

function init_ssh() {
  _enable_and_start_ssh
  _add_host_keys
  modify_ssh_config "PermitRootLogin" "prohibit-password" "yes"
  modify_ssh_config "PubkeyAuthentication" "yes" "yes"
  modify_ssh_config "PasswordAuthentication" "yes" "yes"
  modify_ssh_config "PermitEmptyPasswords" "no" "no"
  set_user_permission "root"
  set_user_permission "ubuntu"
}

# Function to display key SSH configurations
function view_ssh_config() {
  echo "SSH Settings:"
  # List of key configurations to display
  _display_config "Port"
  _display_config "PermitRootLogin"
  _display_config "PasswordAuthentication"
  _display_config "PubkeyAuthentication"
  _display_config "PermitEmptyPasswords"

  _display_config "MaxAuthTries"
  _display_config "ClientAliveCountMax"
  _display_config "ClientAliveInterval"

  # Determines whether TCP connection keep-alive is enabled. It is recommended that this be set to "yes" to avoid connection timeouts.
  _display_config "TCPKeepAlive"
  _display_config "AllowTcpForwarding"
  # Determines if X11 forwarding is allowed. If you do not need to run graphical applications in an SSH session, it is recommended that this be set to "no".
  _display_config "X11Forwarding"

  # Specifies the logging level. The default is "INFO", but in production environments it can be set to a higher level (such as "VERBOSE" or "DEBUG") for detailed logging.
  _display_config "LogLevel"
  # Determines whether Pluggable Authentication Modules (PAM) are used for authentication. It is recommended that this be set to yes to provide advanced authentication features
  _display_config "UsePAM"
  _display_config "AllowUsers"
}

function vim_change_sshd_config() {
  sudo vim "$SSH_CONFIG_FILE"
  sudo systemctl restart sshd.service
}

# Function to change SSH port
function change_ssh_port() {
  read -p "Enter new SSH port: " new_port

  # Check that the port number is in the valid range
  if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
      # Find the existing Port configuration and replace it with the new port number
      if grep -q "^Port " "$SSH_CONFIG_FILE"; then
          sudo sed -i "s/^Port .*/Port $new_port/" "$SSH_CONFIG_FILE"
      else
          echo "Port $new_port" | sudo tee -a "$SSH_CONFIG_FILE"
      fi
      echo "SSH port changed to $new_port"
      sudo systemctl restart sshd.service
  else
      echo "Invalid port. Please enter a number between 1 and 65535."
  fi
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

# Function to toggle PermitRootLogin
function toggle_permit_root_login() {
  echo "Current PermitRootLogin setting:"
  grep "^PermitRootLogin" "$SSH_CONFIG_FILE"
  
  read -p "Set PermitRootLogin (yes/no/prohibit-password): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" || "$choice" == "prohibit-password" ]]; then
    modify_ssh_config "PermitRootLogin" "prohibit-password" $choice
    echo "PermitRootLogin set to $choice"
  else
    echo "Invalid input. Please enter 'yes', 'no', or 'prohibit-password'."
  fi
  sudo systemctl restart sshd.service
}

# Toggle Public Key Authentication
function toggle_pubkey_authentication() {
  read -p "Enable Pubkey Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    modify_ssh_config "PubkeyAuthentication" "yes" $choice
    echo "Pubkey Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  sudo systemctl restart sshd.service
}

# Function to enable or disable password authentication
function toggle_password_authentication() {
  read -p "Enable Password Authentication? (yes/no): " choice
  if [[ "$choice" == "yes" || "$choice" == "no" ]]; then
    modify_ssh_config "PasswordAuthentication" "no" $choice
    echo "Password Authentication set to $choice"
  else
    echo "Invalid input. Please enter 'yes' or 'no'."
  fi
  sudo systemctl restart sshd.service
}

# Function to backup the SSH configuration file
function backup_ssh_config() {
  local backup_file="$SSH_CONFIG_FILE-$(date +%F-%H%M%S)"
  if sudo cp "$SSH_CONFIG_FILE" "$backup_file"; then
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
      sudo cp "$backup_file" "$SSH_CONFIG_FILE"
      echo "Configuration restored from $backup_file"
      sudo systemctl restart sshd.service
  else
      echo "Backup file not found."
  fi
}

function reinstall_ssh() {
  echo "Reinstalling SSH..."
  _confirm_operation || return
  if sudo apt autoremove -y openssh-server && sudo apt-get install --reinstall openssh-server; then
    init_ssh
    echo "SSH reinstalled and service restarted."
  else
    echo "Error occurred during SSH reinstallation."
  fi
}

function root_path_check() {
  if [ ! -d "/root/.ssh" ]; then
      sudo mkdir -p /root/.ssh
      sudo chmod 700 /root/.ssh
  fi
  if [ ! -f "/root/.ssh/authorized_keys" ]; then
      sudo touch /root/.ssh/authorized_keys
      sudo chmod 600 /root/.ssh/authorized_keys
  fi
}

function edit_root_authorized_keys() {
  root_path_check
  sudo vim /root/.ssh/authorized_keys
}

function reset_root_authorized_keys() {
  if _confirm_operation; then
      root_path_check
      if [ -f "/root/.ssh/authorized_keys" ]; then
          sudo rm /root/.ssh/authorized_keys
      fi
      sudo mkdir -p /root/.ssh
      sudo touch /root/.ssh/authorized_keys
      sudo chmod 700 /root/.ssh
      sudo chmod 600 /root/.ssh/authorized_keys
      echo "authorized_keys file reset and permissions set, please put in your public keys in this file"
      sudo systemctl restart sshd.service
  else
      echo "Operation cancelled."
  fi
}

function set_user_permission() {
  local username="$1"
  if [ -z "$username" ]; then
      read -p "Enter username: " username
  fi
  if ! _user_exists "$username"; then
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
      echo -e "\nAllowUsers $username" | sudo tee -a "$SSH_CONFIG_FILE"
      echo "AllowUsers with user $username added to SSH config."
  fi
  sudo systemctl restart sshd.service
}

function get_user_group() {
  local username="$1"
  group=$(id -gn "$username")
  echo "$group"
}

function user_path_check() {
  local username="$1"
  if [ -z "$username" ]; then
      read -p "Enter username: " username
  fi
  group=$(get_user_group "$username")
  if [ ! -d "/home/$username/.ssh" ]; then
      sudo mkdir -p /home/$username/.ssh
      sudo chown "$username:$group" "/home/$username/.ssh"
      sudo chmod 700 /home/$username/.ssh
  fi
  if [ ! -f "/home/$username/.ssh/authorized_keys" ]; then
      sudo touch /home/$username/.ssh/authorized_keys
      sudo chown "$username:$group" "/home/$username/.ssh/authorized_keys"
      sudo chmod 600 /home/$username/.ssh/authorized_keys
  fi
}

function edit_user_authorized_keys() {
  local username="$1"
  if [ -z "$username" ]; then
      read -p "Enter username: " username
  fi
  if ! _user_exists "$username"; then
    echo "User $username does not exist."
    return
  fi
  user_path_check "$username"
  sudo vim /home/$username/.ssh/authorized_keys
}

function update_user_authorized_keys() {
  local username="$1"
  if [ -z "$username" ]; then
      read -p "Enter username: " username
  fi
  echo "Users existing authorized_keys files will be overwritten by root one"
  _confirm_operation || return
  if ! _user_exists "$username"; then
    echo "User $username does not exist."
    return
  fi
  user_path_check "$username"
  sudo cat /root/.ssh/authorized_keys > /home/$username/.ssh/authorized_keys
}

function generate_ssh_keys() {
  if [ ! -d "/root/.ssh" ]; then
    sudo mkdir -p /root/.ssh
    sudo chmod 700 /root/.ssh
  fi
  if [ ! -f "/root/.ssh/authorized_keys" ]; then
    sudo touch /root/.ssh/authorized_keys
    sudo chmod 600 /root/.ssh/authorized_keys
  fi
  ssh-keygen -t rsa -b 4096 -N '' -f /tmp/tempkey
  public_key=$(cat /tmp/tempkey.pub)
  echo "$public_key" >> /root/.ssh/authorized_keys
  echo "Generated private key:"
  cat /tmp/tempkey
  sudo rm /tmp/tempkey.pub
  sudo rm /tmp/tempkey
  read -p "Please keep your key carefully. Press Enter to continue..."
  clear
}
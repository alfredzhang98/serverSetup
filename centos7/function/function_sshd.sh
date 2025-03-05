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

function _add_host_keys() {
  local host_keys=(
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_dsa_key"
    "/etc/ssh/ssh_host_ecdsa_key"
    "/etc/ssh/ssh_host_ed25519_key"
  )

  if [[ -f "$SSH_CONFIG_FILE" ]]; then
    for key_file in "${host_keys[@]}"; do
      if ! grep -q "^HostKey $key_file" "$SSH_CONFIG_FILE"; then
        echo "HostKey $key_file" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
      fi
    done
  else
    echo "Error: $SSH_CONFIG_FILE not found."
  fi
}

function _display_config() {
  local config_key="$1"
  local config_value
  config_value=$(grep -E "^[[:space:]]*#?[[:space:]]*$config_key[[:space:]]+" "$SSH_CONFIG_FILE" | tail -1 | awk '{print $2}')
  if [ -z "$config_value" ]; then
      config_value="Not Set/Commented Out"
  fi
  echo "$config_key: $config_value"
}

function init_ssh() {
  _enable_and_start_ssh
  _add_host_keys
  modify_ssh_config "PermitRootLogin" "prohibit-password"
  modify_ssh_config "PubkeyAuthentication" "yes"
  modify_ssh_config "PasswordAuthentication" "yes"
  modify_ssh_config "PermitEmptyPasswords" "no"
  set_user_permission "root"
}

function view_ssh_config() {
  echo "SSH Settings:"
  for key in Port PermitRootLogin PasswordAuthentication PubkeyAuthentication PermitEmptyPasswords MaxAuthTries ClientAliveCountMax ClientAliveInterval TCPKeepAlive AllowTcpForwarding X11Forwarding LogLevel UsePAM AllowUsers; do
    _display_config "$key"
  done
}

# 优化后的 modify_ssh_config 函数：支持更灵活的匹配模式（允许多余空格和注释符号）
function modify_ssh_config() {
  local config_name="$1"
  local choice="$2"
  local pattern="^[[:space:]]*#?[[:space:]]*$config_name[[:space:]]+.*"
  if grep -Eq "$pattern" "$SSH_CONFIG_FILE"; then
      sudo sed -i -E "s|$pattern|$config_name $choice|" "$SSH_CONFIG_FILE"
  else
      echo "$config_name $choice" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
  fi
}

# 优化后的 change_ssh_port 函数：如果 Port 行不存在则追加配置
function change_ssh_port() {
  read -p "Enter new SSH port: " new_port
  if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
      if grep -Eq "^[[:space:]]*#?[[:space:]]*Port[[:space:]]+" "$SSH_CONFIG_FILE"; then
          sudo sed -i -E "s|^[[:space:]]*#?[[:space:]]*Port[[:space:]]+.*|Port $new_port|" "$SSH_CONFIG_FILE"
      else
          echo "Port $new_port" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
      fi
      echo "SSH port changed to $new_port"
      sudo systemctl restart sshd.service
  else
      echo "Invalid port. Please enter a number between 1 and 65535."
  fi
}

function backup_ssh_config() {
  local backup_file="$SSH_CONFIG_FILE-$(date +%F-%H%M%S)"
  if sudo cp "$SSH_CONFIG_FILE" "$backup_file"; then
      echo "Backup created: $backup_file"
  else
      echo "Error: Failed to create backup."
  fi
}

function restore_ssh_config() {
  echo "Available backups:"
  ls -l "$SSH_CONFIG_FILE"-*
  read -p "Enter backup file to restore: " backup_file
  if [ -f "$backup_file" ]; then
      sudo cp "$backup_file" "$SSH_CONFIG_FILE"
      echo "Configuration restored."
      sudo systemctl restart sshd.service
  else
      echo "Backup file not found."
  fi
}

function reinstall_ssh() {
  echo "Reinstalling SSH..."
  _confirm_operation || return
  if sudo yum remove -y openssh-server && sudo yum install -y openssh-server; then
    init_ssh
    echo "SSH reinstalled and restarted."
  else
    echo "Error reinstalling SSH."
  fi
}

# 优化后的 set_user_permission 函数：
# 1. 如果已存在 AllowUsers 且已包含该用户则不做修改
# 2. 如果存在 AllowUsers 但不包含该用户，则将用户添加到第一行 AllowUsers 中
# 3. 如果没有 AllowUsers 行，则追加新的 AllowUsers 配置
function set_user_permission() {
  local username="$1"
  if ! _user_exists "$username"; then
      echo "User $username does not exist."
      return
  fi
  if grep -Eq "^[[:space:]]*AllowUsers.*\b$username\b" "$SSH_CONFIG_FILE"; then
      echo "User $username is already allowed."
  elif grep -Eq "^[[:space:]]*AllowUsers" "$SSH_CONFIG_FILE"; then
      sudo sed -i -E "0,/^[[:space:]]*AllowUsers/ s//& $username/" "$SSH_CONFIG_FILE"
  else
      echo "AllowUsers $username" | sudo tee -a "$SSH_CONFIG_FILE" > /dev/null
  fi
  sudo systemctl restart sshd.service
}

function root_path_check() {
  sudo mkdir -p /root/.ssh
  sudo chmod 700 /root/.ssh
  sudo touch /root/.ssh/authorized_keys
  sudo chmod 600 /root/.ssh/authorized_keys
}

function edit_root_authorized_keys() {
  root_path_check
  sudo vim /root/.ssh/authorized_keys
}

function reset_root_authorized_keys() {
  _confirm_operation || return
  root_path_check
  sudo rm /root/.ssh/authorized_keys
  sudo touch /root/.ssh/authorized_keys
  sudo chmod 600 /root/.ssh/authorized_keys
  echo "authorized_keys file reset."
  sudo systemctl restart sshd.service
}

function generate_ssh_keys() {
  local key_file="/root/.ssh/id_rsa"
  root_path_check

  if [ -f "$key_file" ]; then
    echo "SSH key already exists at $key_file"
    return
  fi

  sudo ssh-keygen -t rsa -b 4096 -N '' -f "$key_file"
  sudo chmod 600 "$key_file" "$key_file.pub"
  cat "$key_file.pub" | sudo tee -a /root/.ssh/authorized_keys >/dev/null
  sudo systemctl restart sshd.service

  echo "SSH key generated at $key_file. Keep it safe!"
}

function edit_user_authorized_keys() {
  local username="$1"
  if ! _user_exists "$username"; then
    echo "User $username does not exist."
    return
  fi
  sudo mkdir -p "/home/$username/.ssh"
  sudo chmod 700 "/home/$username/.ssh"
  sudo touch "/home/$username/.ssh/authorized_keys"
  sudo chmod 600 "/home/$username/.ssh/authorized_keys"
  sudo vim "/home/$username/.ssh/authorized_keys"
}

function update_user_authorized_keys() {
  local username="$1"
  if ! _user_exists "$username"; then
    echo "User $username does not exist."
    return
  fi
  _confirm_operation || return
  sudo cat /root/.ssh/authorized_keys > "/home/$username/.ssh/authorized_keys"
}
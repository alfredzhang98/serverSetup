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
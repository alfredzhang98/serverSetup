#!/bin/bash

# Function to view current groups
function view_group() {
  echo "Current groups:"
  cat /etc/group
}

# Function to add a new group
function add_group() {
  read -p "Enter new group name: " groupname
  if [ -n "$groupname" ]; then
    if ! getent group "$groupname" >/dev/null; then
      sudo groupadd "$groupname"
      grep "$groupname" /etc/group
    else
      echo "Group $groupname already exists."
    fi
  else
    echo "Invalid input!"
  fi
  view_group
}

# Function to delete group
function delete_group() {
  read -p "Enter group name: " groupname
  if [ -n "$groupname" ]; then
    if getent group "$groupname" >/dev/null; then
      sudo groupdel "$groupname"
      echo "Group $groupname deleted."
    else
      echo "Group $groupname does not exist."
    fi
  else
    echo "Invalid input!"
  fi
  view_group
}

# Function to view user account info
function view_user() {
  echo "Current users:"
  while IFS=: read -r user _; do
    groups=$(groups $user | cut -d' ' -f2-)
    echo "$user $groups"
  done < <(getent passwd)
}

# Function to add a user and assign to a group
function add_user() {
  read -p "Enter username: " username
  read -p "Enter password: " -s password1
  echo
  read -p "Confirm password: " -s password2
  echo

  # Compare passwords
  attempts=1
  while [ "$password1" != "$password2" ]; do
    if [ $attempts -eq 3 ]; then
      echo "Passwords do not match. Exiting..."
      return
    fi

    echo "Passwords do not match. Please try again."
    read -p "Enter password: " -s password1
    echo
    read -p "Confirm password: " -s password2
    echo

    attempts=$((attempts + 1))
  done

  read -p "Enter group (or leave blank for default): " group

  [ -z "$group" ] && group="unclassified"

  if ! getent group "$group" >/dev/null; then
    echo "Group $group does not exist. Please add the correct group first."
    return
  fi

  if id -u "$username" >/dev/null 2>&1; then
    echo "User $username already exists. Please choose a different username."
    return
  fi

  # Check if mailbox file exists
  if [ -f "/var/mail/$username" ]; then
    echo "Mailbox file for user $username already exists. Skipping mailbox creation."
  else
    sudo useradd -g "$group" -m "$username"
    echo "$username:$password1" | sudo chpasswd
  fi

  if ! grep -q "^AllowUsers $username" /etc/ssh/sshd_config; then
    echo "AllowUsers $username" >> /etc/ssh/sshd_config
    sudo systemctl restart sshd.service
    sudo systemctl enable sshd.service
  fi

  if [ ! -d "/home/$username/.ssh" ]; then
    sudo mkdir -p "/home/$username/.ssh"
  fi

  cat /root/.ssh/authorized_keys > /home/$username/.ssh/authorized_keys
  sudo chown "$username:$group" "/home/$username/.ssh"
  sudo chmod 700 "/home/$username/.ssh"
  sudo chown "$username:$group" "/home/$username/.ssh/authorized_keys"
  sudo chmod 600 "/home/$username/.ssh/authorized_keys"
}



# Function to delete a user
function delete_user() {
  read -p "Enter username: " username

  if id "$username" &>/dev/null; then
    read -p "Confirm delete user $username? (y/n) " confirm
    if [ "$confirm" = "y" ]; then
      # Delete mailbox file
      if [ -f "/var/mail/$username" ]; then
        sudo rm "/var/mail/$username"
        echo "Mailbox file for user $username deleted."
      fi

      # Delete user's home directory
      read -p "Delete home directory /home/$username? (y/n) " delete_home
      if [ "$delete_home" = "y" ]; then
        sudo userdel -r "$username"
        echo "User $username and home directory deleted."
      else
        sudo userdel "$username"
        echo "User $username deleted."
      fi

      # Remove user from SSH configuration
      sudo sed -i "/$username/d" /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
      sudo systemctl enable sshd.service
    else
      echo "Delete canceled."
    fi
  else
    echo "User $username does not exist."
  fi
}

# Function to change user password
function modify_user_password() {
  read -p "Enter username: " username
  sudo passwd "$username"
  echo "Password changed for $username."
}

# Function to modify user's group
function modify_user_group() {
  read -p "Enter username: " username
  read -p "Enter new group: " newgroup
  if getent group "$newgroup" >/dev/null; then
    sudo usermod -g "$newgroup" "$username"
    echo "Changed group for $username to $newgroup."
  else
    echo "Group $newgroup does not exist."
  fi
}

# Function to modify user permissions
function modify_user_permissions() {
  read -p "Enter username: " username
  # Show current permissions
  echo "Current permissions:"
  sudo su "$username" -c 'sudo -l'

  if ! grep -q "$username" /etc/sudoers; then
    read -p "$username currently has no sudo privilege. Add privilege? (y/n) " add
    if [ "$add" = "y" ]; then
      read -p "Enter sudo permission for $username (ALL is easy choice): " sudo_permission
      echo "$username ALL=(ALL) $sudo_permission" >> /etc/sudoers
      echo "Added sudo privilege for $username."
    else
      echo "Sudo privilege unchanged for $username."
    fi
  else
    read -p "$username currently has sudo privilege. Revoke privilege? (y/n) " revoke
    if [ "$revoke" = "y" ]; then
      sudo sed -i "/$username/d" /etc/sudoers
      echo "Revoked sudo privilege for $username."
    else
      echo "Sudo privilege unchanged for $username."
    fi
  fi
}

# Function to lock a user account
function lock_user() {
  read -p "Enter username to lock: " username
  if id "$username" &>/dev/null; then
    sudo passwd -l "$username"
    echo "Account for $username has been locked."
  else
    echo "User $username does not exist."
  fi
}

# Function to unlock a user account
function unlock_user() {
  read -p "Enter username to unlock: " username
  if id "$username" &>/dev/null; then
    sudo passwd -u "$username"
    echo "Account for $username has been unlocked."
  else
    echo "User $username does not exist."
  fi
}

# Function for group setting menu
function group_setting_menu() {
  while :; do
    echo "1. View group"
    echo "2. Add group"
    echo "3. Delete group"
    echo "0. Back to main menu"
    read -p "Enter selection: " selection

    case $selection in
    1) view_group ;;
    2) add_group ;;
    3) delete_group ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}

# Function for user setting menu
function user_setting_menu() {
  while :; do
    echo -e "\033[32m1. View user\033[0m"
    echo -e "\033[32m2. Add user\033[0m"
    echo -e "\033[32m3. Delete user\033[0m"
    echo -e "\033[32m4. Modify user password\033[0m"
    echo -e "\033[32m5. Modify user group\033[0m"
    echo -e "\033[32m6. Modify user permissions\033[0m"
    echo -e "\033[32m7. Lock user account\033[0m"
    echo -e "\033[32m8. Unlock user account\033[0m"
    echo -e "\033[32m0. Back to main menu\033[0m"
    read -p "Enter selection: " selection

    case $selection in
    1) view_user ;;
    2) add_user ;;
    3) delete_user ;;
    4) modify_user_password ;;
    5) modify_user_group ;;
    6) modify_user_permissions ;;
    7) lock_user ;;
    8) unlock_user ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}

# Main menu
echo "****************************************************************"
echo "Make sure the group exists before setting a new user"
echo "****************************************************************"

main_menu() {
  while true; do
    echo -e "\033[32m1. Group setting\033[0m"
    echo -e "\033[32m2. User setting\033[0m"
    echo -e "\033[32m0. Quit\033[0m"
    read -p "Enter selection: " selection

    case $selection in
    1) group_setting_menu ;;
    2) user_setting_menu ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
  done
}
main_menu
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
      groupadd "$groupname"
      grep "$groupname" /etc/group
    else
      echo "Group $groupname already exists."
    fi
  else
    echo "Invalid input!"
  fi
  view_group
}

# Function to delete a group
function delete_group() {
  read -p "Enter group name: " groupname
  if [ -n "$groupname" ]; then
    if ! getent group "$groupname" >/dev/null; then
      echo "Group $groupname does not exist."
    else
      groupdel "$groupname"
      echo "Group $groupname deleted."
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
  read -p "Enter password: " -s password
  echo
  read -p "Enter group (or leave blank for default): " group

  [ -z "$group" ] && group="unclassified"

  if ! getent group "$group" >/dev/null; then
    echo "You should add a right group first."
  else
    useradd -g "$group" -m "$username"
    echo -e "$password\n$password" | passwd "$username"
    echo "AllowUsers $username" >> /etc/ssh/sshd_config
    systemctl restart sshd.service
    systemctl enable sshd.service
  fi
  view_user
}

# Function to delete a user
function delete_user() {
  read -p "Enter username: " username

  if id "$username" &>/dev/null; then
    read -p "Confirm delete user $username? (y/n) " confirm
    if [ "$confirm" = "y" ]; then
      userdel "$username"
      echo "User $username deleted."
      sed -i "/$username/d" /etc/ssh/sshd_config
      systemctl restart sshd.service
      systemctl enable sshd.service
    else
      echo "Delete canceled."
    fi
  else
    echo "User $username does not exist."
  fi
  view_user
}

# Function to change user password
function modify_user_password() {
  read -p "Enter username: " username
  passwd "$username"
  echo "Password changed for $username."
}

# Function to modify user's group
function modify_user_group() {
  read -p "Enter username: " username
  read -p "Enter new group: " newgroup
  if getent group "$newgroup" >/dev/null; then
    usermod -g "$newgroup" "$username"
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
  su "$username" -c 'sudo -l'

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
      sed -i "/$username/d" /etc/sudoers
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
    passwd -l "$username"
    echo "Account for $username has been locked."
  else
    echo "User $username does not exist."
  fi
}

# Function to unlock a user account
function unlock_user() {
  read -p "Enter username to unlock: " username
  if id "$username" &>/dev/null; then
    passwd -u "$username"
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
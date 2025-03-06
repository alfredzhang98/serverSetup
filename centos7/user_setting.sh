#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

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

# Function to delete group
function delete_group() {
  read -p "Enter group name: " groupname
  if [ -n "$groupname" ]; then
    if getent group "$groupname" >/dev/null; then
      groupdel "$groupname"
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
    useradd -g "$group" -m "$username"
    echo "$username:$password1" | chpasswd
  fi
  set_user_permission "$username"
  user_path_check "$username"
  update_user_authorized_keys "$username"
}



# Function to delete a user
function delete_user() {
  read -p "Enter username: " username

  if id "$username" &>/dev/null; then
    read -p "Confirm delete user $username? (y/n) " confirm
    if [ "$confirm" = "y" ]; then
      # Delete mailbox file
      if [ -f "/var/mail/$username" ]; then
        rm "/var/mail/$username"
        echo "Mailbox file for user $username deleted."
      fi

      # Delete user's home directory
      read -p "Delete home directory /home/$username? (y/n) " delete_home
      if [ "$delete_home" = "y" ]; then
        userdel -r "$username"
        echo "User $username and home directory deleted."
      else
        userdel "$username"
        echo "User $username deleted."
      fi

      # Remove user from SSH configuration
      sed -i "/$username/d" /etc/ssh/sshd_config
      systemctl restart sshd.service
      systemctl enable sshd.service
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
    echo -e "${GREEN}******** Group Management Menu ********${RESET}"
    echo -e "${GREEN} 1.  View Group${RESET}"
    echo -e "${GREEN} 2.  Add Group${RESET}"
    echo -e "${GREEN} 3.  Delete Group${RESET}"
    echo -e "${GREEN}***************************************${RESET}"
    echo -e "${GREEN} 0.  Back to Main Menu${RESET}"
    echo -e "${GREEN}***************************************${RESET}"

    read -p "Enter selection: " selection

    case $selection in
    1) view_group ;;
    2) add_group ;;
    3) delete_group ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
    read -p "Press Enter to continue..."
  done
}

# Function for user setting menu
function user_setting_menu() {
  while :; do
    echo -e "${GREEN}******** User Management Menu ********${RESET}"
    echo -e "${GREEN} 1.  View User${RESET}"
    echo -e "${GREEN} 2.  Add User${RESET}"
    echo -e "${GREEN} 3.  Delete User${RESET}"
    echo -e "${GREEN} 4.  Modify User Password${RESET}"
    echo -e "${GREEN} 5.  Modify User Group${RESET}"
    echo -e "${GREEN} 6.  Modify User Permissions${RESET}"
    echo -e "${GREEN} 7.  Lock User Account${RESET}"
    echo -e "${GREEN} 8.  Unlock User Account${RESET}"
    echo -e "${GREEN}*************************************${RESET}"
    echo -e "${GREEN} 0.  Back to Main Menu${RESET}"
    echo -e "${GREEN}*************************************${RESET}"

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
    read -p "Press Enter to continue..."
  done
}

# Main menu
echo "****************************************************************"
echo "Make sure the group exists before setting a new user"
echo "****************************************************************"

main_menu() {
  while true; do
    echo -e "${GREEN}******** User & Group Management Menu ********${RESET}"
    echo -e "${GREEN} 1.  Group Setting${RESET}"
    echo -e "${GREEN} 2.  User Setting${RESET}"
    echo -e "${GREEN}*********************************************${RESET}"
    echo -e "${GREEN} 0.  Exit${RESET}"
    echo -e "${GREEN}*********************************************${RESET}"

    read -p "Enter selection: " selection

    case $selection in
    1) group_setting_menu ;;
    2) user_setting_menu ;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
    read -p "Press Enter to continue..."
  done
}

FUNCTION_SSHD="./function/function_sshd.sh"
if [[ ! -f "$FUNCTION_SSHD" ]]; then
    echo -e "${RED}Error: function_sshd.sh not found!${RESET}"
    read -rp "Do you want to continue without it? (y/N): " choice
    case $choice in
        [Yy]* ) echo -e "${YELLOW}Continuing without function_sshd.sh...${RESET}" ;;
        * ) echo "Exiting script."; exit 1 ;;
    esac
else
    source "$FUNCTION_SSHD"
fi

main_menu
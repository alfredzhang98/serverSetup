#!/bin/bash

# view current groups
view_group() {
  echo "Current groups:"
  cat /etc/group
}

# Create a new group
add_group() {
  read -p "Enter new group name: " groupname
  if [ -n "$groupname" ]; then
    if ! getent group "$groupname" >/dev/null; then
      groupadd $groupname
      cat /etc/group | grep $groupname
    else
      echo "Group $groupname has been added."
    fi
  else
    echo "Wrong input!"
  fi
  view_group
}

# Delete a group
delete_group() {
  read -p "Enter group name: " groupname
  if [ -n "$groupname" ]; then

    if ! getent group "$groupname" >/dev/null; then
      echo "Group $groupname is not exist."
    else
      groupdel "$groupname"
      echo "Group $groupname deleted."
    fi
  else
    echo "Wrong input!"
  fi
  view_group
}

# View user account info
view_user() {
  echo "Current users:"
  for user in $(ls /home); do
    groups=$(groups $user | cut -d' ' -f2-)
    echo "$user $groups"
  done
}

# Add a user and assign to group
add_user() {
  read -p "Enter username: " username
  read -p "Enter password: " password
  read -p "Enter group (or leave blank for default): " group

  if [ -z "$group" ]; then
    $group="unclassified"
  fi

  if ! getent group "$group" >/dev/null; then
    echo "You should add a right group first"
  else
    useradd -g "$group" -m "$username"
    echo "$password" | passwd --stdin "$username"
    echo "AllowUsers $username" >>/etc/ssh/sshd_config
    systemctl restart sshd.service
    systemctl enable sshd.service
  fi
  view_user
}

# Delete a user
delete_user() {
  read -p "Enter username: " username

  if id "$username" &>/dev/null; then
    read -p "Confirm delete user $username? (y/n) " confirm
    if [ "$confirm" = "y" ]; then
      chown -R root:root /home/"$username"
      rm -rf /home/"$username"
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

# Change user password
modify_user_password() {
  read -p "Enter username: " username
  passwd "$username"
  echo "Password changed for $username."
}

# Modify user's group
modify_user_group() {
  read -p "Enter username: " username
  read -p "Enter new group: " newgroup
  usermod -g $newgroup $username
  echo "Changed group for $username to $newgroup."
}

# Modify user permissions
modify_user_permissions() {
  read -p "Enter username: " username
  # Show current permissions
  echo "Current permissions:"
  su "$username" -c 'sudo -l'

  has_sudo=$(grep -c "$username" /etc/sudoers)
  if [ $has_sudo -eq 0 ]; then
    read -p "$username currently has no sudo privilege. Add privilege? (y/n) " add
    if [ "$add" = "y" ]; then
      read -p "Enter sudo permission for $username ("ALL" is easy choice): " sudo_permission
      echo "$username ALL=(ALL) $sudo_permission" >>/etc/sudoers
      echo "Added sudo privilege for $username"
    elif [ "$add" = "n" ]; then
      echo "Sudo privilege unchanged for $username"
    fi
  else
    read -p "$username currently has sudo privilege. Revoke privilege? (y/n) " revoke
    if [ "$revoke" = "y" ]; then
      echo "Sudo privilege unchanged for $username"
    elif [ "$revoke" = "n" ]; then
      sed -i "/$username/d" /etc/sudoers
      echo "Revoked sudo privilege for $username"
    fi
  fi
}

group_setting() {
  while :; do
    echo -e "\033[32m 1. View group \033[0m"
    echo -e "\033[32m 2. Add group \033[0m"
    echo -e "\033[32m 3. Delete group \033[0m"
    echo -e "\033[32m 0. Back to main list \033[0m"
    echo -e "\033[32m ******** \033[0m"
    read -p "Enter selection: " selection

    case $selection in
    1) view_group ;;
    2) add_group ;;
    3) delete_group ;;
    0) break ;;
    *) echo "Invalid selection" ;;
    esac
  done
}

user_setting() {
  while :; do
    echo -e "\033[32m 1. View user \033[0m"
    echo -e "\033[32m 2. Add user \033[0m"
    echo -e "\033[32m 3. Delete user \033[0m"
    echo -e "\033[32m 4. Modify user password \033[0m"
    echo -e "\033[32m 5. Modify user group \033[0m"
    echo -e "\033[32m 6. Modify user permissions \033[0m"
    echo -e "\033[32m 0. Back to main list \033[0m"
    echo -e "\033[32m ******** \033[0m"
    read -p "Enter selection: " selection

    case $selection in
    1) view_user ;;
    2) add_user ;;
    3) delete_user ;;
    4) modify_user_password ;;
    5) modify_user_group ;;
    6) modify_user_permissions ;;
    0) break ;;
    *) echo "Invalid selection" ;;
    esac
  done
}

# Main menu
echo "****************************************************************"
echo "Group should be make sure before setting a new user"
echo "****************************************************************"

while :; do
  echo -e "\033[32m ********"
  echo -e "\033[32m 1. Group setting"
  echo -e "\033[32m 2. User setting"
  echo -e "\033[32m 0. Quit"
  echo -e "\033[32m ********"
  read -p "Enter selection: " selection

  case $selection in
  1) group_setting ;;
  2) user_setting ;;
  0) break ;;
  *) echo "Invalid selection" ;;
  esac
done

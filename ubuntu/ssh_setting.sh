#!/bin/bash

# Main menu function
main_menu() {
  echo -e "\033[32m Makesure we have su permission \033[0m"
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
    11) sudo systemctl status sshd.service ;;
    12) enable_and_start_ssh ;;
    13) sudo systemctl restart sshd.service ;;

    20) edit_root_authorized_keys ;;
    21) reset_root_authorized_keys ;;
    22) set_user_permission ;;
    23) edit_user_authorized_keys ;;
    24) update_user_authorized_keys ;;
    25) generate_ssh_keys;;
    0) break ;;
    *) echo "Invalid selection." ;;
    esac
    read -p "Press Enter to continue..."
  done
}

if [[ $EUID -eq 0 ]]; then
    echo "The current user is root"
else
    echo "The current user is not root"
    exit 1
fi
source ./function/function_ssh.sh
main_menu

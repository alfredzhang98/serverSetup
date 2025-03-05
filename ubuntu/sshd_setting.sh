#!/bin/bash

# 设置颜色变量
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 错误处理，退出时输出提示信息
trap 'echo -e "${YELLOW}Exiting script safely.${RESET}"; exit 1' ERR

# 检查当前用户是否为 root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR] This script requires root privileges!${RESET}"
    echo -e "${YELLOW}Try running: sudo $0${RESET}"
    read -rp "Do you want to restart with sudo? (y/N): " choice
    case $choice in
        [Yy]* ) exec sudo bash "$0";;
        * ) echo "Exiting script. Please run as root."; exit 1;;
    esac
fi

# 加载 function_sshd.sh 文件
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

# 主菜单函数
main_menu() {
  while true; do
    clear
    echo -e "${GREEN}******** SSH Configuration Menu ********${RESET}"
    echo -e "${GREEN} 1.  View SSH Configuration${RESET}"
    echo -e "${GREEN} 2.  Edit SSH Config with Vim${RESET}"
    echo -e "${GREEN} 3.  Change SSH Port${RESET}"
    echo -e "${GREEN} 4.  Toggle PermitRootLogin${RESET}"
    echo -e "${GREEN} 5.  Toggle Public Key Authentication${RESET}"
    echo -e "${GREEN} 6.  Toggle Password Authentication${RESET}"
    echo -e "${GREEN} 7.  Backup SSH Configuration${RESET}"
    echo -e "${GREEN} 8.  Restore SSH Configuration${RESET}"
    echo -e "${GREEN}10.  Reinstall SSH${RESET}"
    echo -e "${GREEN}11.  Check SSH Service Status${RESET}"
    echo -e "${GREEN}12.  Enable and Start SSH Service${RESET}"
    echo -e "${GREEN}13.  Restart SSH Service${RESET}"
    echo -e "${GREEN}20.  Edit root authorized_keys${RESET}"
    echo -e "${GREEN}21.  Reset root authorized_keys${RESET}"
    echo -e "${GREEN}22.  Set User SSH Permission${RESET}"
    echo -e "${GREEN}23.  Edit User authorized_keys${RESET}"
    echo -e "${GREEN}24.  Update User authorized_keys${RESET}"
    echo -e "${GREEN}25.  Generate SSH Key Pairs${RESET}"
    echo -e "${GREEN} 0.  Quit${RESET}"
    
    read -rp "Enter selection: " selection
    
    case $selection in
      1) view_ssh_config ;;
      2) vim_change_sshd_config ;;
      3) change_ssh_port ;;
      4) toggle_permit_root_login ;;
      5) toggle_pubkey_authentication ;;
      6) toggle_password_authentication ;;
      7) backup_ssh_config ;;
      8) restore_ssh_config ;;
      10) reinstall_ssh ;;
      11) sudo systemctl status sshd.service || echo -e "${RED}Failed to check SSH service status.${RESET}" ;;
      12) _enable_and_start_ssh ;;
      13) sudo systemctl restart sshd.service ;;
      20) edit_root_authorized_keys ;;
      21) reset_root_authorized_keys ;;
      22) 
          read -p "Enter username to allow SSH access: " username
          if [[ -n "$username" ]]; then
              set_user_permission "$username"
          else
              echo -e "\033[31mError: Username cannot be empty.\033[0m"
          fi
          ;;
      23) 
          read -p "Enter username: " username
          if [[ -n "$username" ]]; then
              edit_user_authorized_keys "$username"
          else
              echo -e "\033[31mError: Username cannot be empty.\033[0m"
          fi
          ;;
      24) 
          read -p "Enter username: " username
          if [[ -n "$username" ]]; then
              update_user_authorized_keys "$username"
          else
              echo -e "\033[31mError: Username cannot be empty.\033[0m"
          fi
          ;;
      25) generate_ssh_keys ;;
      0) echo -e "${YELLOW}Exiting...${RESET}"; break ;;
      *) echo -e "${RED}Invalid selection.${RESET}" ;;
    esac
    read -rp "Press Enter to continue..."
  done
}

main_menu
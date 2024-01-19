#!/bin/bash

function init_nftables() {
    echo "Initializing nftables..."
    sudo nft flush ruleset
    sudo nft 'add table ip filter'
    sudo nft 'add chain ip filter input { type filter hook input priority 0; policy drop; }'
    sudo nft 'add chain ip filter forward { type filter hook forward priority 0; policy drop; }'
    sudo nft 'add chain ip filter output { type filter hook output priority 0; policy accept; }'
    echo "Basic nftables structure created."
}

function list_rules() {
    echo "Listing all nftables rules..."
    sudo nft list ruleset
}

function add_rule() {
    read -p "Enter the rule to add (e.g., 'add rule ip filter input tcp dport 22 accept'): " rule
    sudo nft "$rule"
    echo "Rule added."
}

function delete_rule() {
    read -p "Enter the rule to delete (e.g., 'delete rule ip filter input tcp dport 22'): " rule
    sudo nft "$rule"
    echo "Rule deleted."
}

function start_nftables() {
    echo "Starting nftables..."
    sudo systemctl start nftables
    echo "nftables started."
}

function stop_nftables() {
    echo "Stopping nftables..."
    sudo systemctl stop nftables
    echo "nftables stopped."
}

function restart_nftables() {
    echo "Restarting nftables..."
    sudo systemctl restart nftables
    echo "nftables restarted."
}

function main_menu() {
    while true; do
        echo -e "\033[32m ******** \033[0m"
        echo -e "\033[32m Nftables Control Menu \033[0m"
        echo -e "\033[32m 1. Initialize nftables \033[0m"
        echo -e "\033[32m 2. List all rules \033[0m"
        echo -e "\033[32m 3. Add a rule \033[0m"
        echo -e "\033[32m 4. Delete a rule \033[0m"
        echo -e "\033[32m 5. Start nftables \033[0m"
        echo -e "\033[32m 6. Stop nftables \033[0m"
        echo -e "\033[32m 7. Restart nftables \033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ******** \033[0m"

        read -p "Enter the corresponding number for the operation: " choice

        case $choice in
        1) init_nftables ;;
        2) list_rules ;;
        3) add_rule ;;
        4) delete_rule ;;
        5) start_nftables ;;
        6) stop_nftables ;;
        7) restart_nftables ;;
        0) echo "Exiting the script"; exit 0 ;;
        *) echo "Invalid selection";;
        esac
        read -p "Press Enter to continue..."
    done
}

main_menu

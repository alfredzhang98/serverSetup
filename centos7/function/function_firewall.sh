#!/bin/bash

function init_firewall() {
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
    sudo firewall-cmd --zone=public --add-service=ssh --permanent
    sudo firewall-cmd --zone=public --add-service=http --permanent
    sudo firewall-cmd --zone=public --add-service=https --permanent
    sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
    sudo firewall-cmd --zone=public --add-port=3389/udp --permanent
    sudo firewall-cmd --zone=public --add-port=3389/tcp --permanent
    sudo firewall-cmd --reload
    sudo systemctl restart firewalld
}

function enable_zone_drifting() {
    echo "Enabling Zone Drifting in firewalld..."
    sed -i 's/AllowZoneDrifting=no/AllowZoneDrifting=yes/' /etc/firewalld/firewalld.conf
    systemctl restart firewalld
    echo "Zone Drifting enabled."
}

function disable_zone_drifting() {
    echo "Disabling Zone Drifting in firewalld..."
    firewall-cmd --set-log-denied=all
    sed -i 's/AllowZoneDrifting=yes/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf
    systemctl restart firewalld
    echo "Zone Drifting disabled."
}
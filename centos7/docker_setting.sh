#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"


function validate_input() {
    if [[ -z "$1" ]]; then
        echo "Input cannot be empty"
        return 1
    fi
}

function confirm_operation() {
    read -p "Are you sure you want to continue? [y/N]: " confirmation
    case $confirmation in
        [Yy]*) return 0 ;;
        *) echo "Operation cancelled"; return 1 ;;
    esac
}

function add_privileged_permission() {
    read -p "Do you want to run the container with privileged permissions? (y/n): " privileged_choice
    case $privileged_choice in
        [Yy]*) echo "--privileged --cap-add SYS_ADMIN" ;;
        *) echo "" ;;
    esac
}

function read_devices() {
    echo "Enter devices to mount (separated by space, press ENTER if none):"
    read -ra devices
    for device in "${devices[@]}"; do
        echo "--device $device "
    done
}

function read_port_mappings() {
    echo "Enter port mappings (format 'host_port:container_port', separated by space, press ENTER if none):"
    read -ra port_mappings
    for port_mapping in "${port_mappings[@]}"; do
        echo "-p $port_mapping "
    done
}

function read_environment_variables() {
    echo "Enter environment variables (format 'VAR=value', separated by space, press ENTER if none):"
    read -ra env_vars
    for env_var in "${env_vars[@]}"; do
        echo "-e $env_var "
    done
}

function choose_run_mode() {
    read -p "Do you want to run the container in detached mode? (y/n): " detached_choice
    case $detached_choice in
        [Yy]*) echo "-d" ;;
        *) echo "-it" ;;
    esac
}

function choose_network_mode() {
    echo "Choose a network mode (host, bridge, press ENTER for default):"
    read network_mode
    case $network_mode in
        host) echo "--net=host" ;;
        bridge) echo "--net=bridge" ;;
        *) echo "" ;;  # No network option will be set if user presses ENTER
    esac
}

function save_container_config() {
    local container_name repository tag host_dir privileges devices port_mappings user env_vars run_mode network_mode yaml_path

    container_name=$1
    repository=$2
    tag=$3
    host_dir=$4
    privileges=$5
    devices=$6
    port_mappings=$7
    user=$8
    env_vars=$9
    run_mode=${10}
    network_mode=${11}
    yaml_path="/home/docker_users/yaml/${container_name}.yaml"

    mkdir -p /home/docker_users/yaml

    echo "container_name: $container_name" > "$yaml_path"
    echo "repository: $repository" >> "$yaml_path"
    echo "tag: $tag" >> "$yaml_path"
    echo "host_dir: $host_dir" >> "$yaml_path"
    echo "privileges: $privileges" >> "$yaml_path"
    echo "devices: $devices" >> "$yaml_path"
    echo "port_mappings: $port_mappings" >> "$yaml_path"
    echo "user: $user" >> "$yaml_path"
    echo "env_vars: $env_vars" >> "$yaml_path"
    echo "run_mode: $run_mode" >> "$yaml_path"
    echo "network_mode: $network_mode" >> "$yaml_path"
}

# Image name and label: Specifies the image to run, e.g. docker run ubuntu:18.04.
# Commands and arguments: Commands and arguments to execute inside the container, such as docker run ubuntu:18.04 /bin/bash.
# Port mapping (-p or --publish): Maps a port inside a container to a port on the host, e.g. -p 8080:80.
# Volume mount (-v or --volume): Mounts a file or directory from the host into the container, e.g. -v /host/path:/container/path.
# Environment variables (-e or --env): Set environment variables within the container, e.g. -e MY_VAR=value, DATABASE_URL=postgresql://db:5432 Increase the flexibility and configurability of your container application by changing the values of environment variables.
## Name (--name): Specifies the name of the container for easy identification and management, such as --name mycontainer.
## Network configuration (--net): Specifies the network mode of the container, e.g. --net=bridge.
## Resource limits: Includes memory (-m or --memory) and CPU (--cpus) limits, such as -m 512m or --cpus=1.5.
# Interactive mode and TTY (-i, -t): -it is usually used together to provide an interactive terminal for the container.
# Run mode: e.g. --detach or -d to make the container run in the background.
# User (-u or --user): Specifies the user who will run the processes in the container.
# Mount device (--device): Mounts a host device into the container, e.g. --device=/dev/sda:/dev/xvdc.
## Health check (--health-cmd, --health-interval, etc.): Configure health check for the container.
## Restart policy (--restart): Set the restart policy for the container, e.g. --restart=always.
## Security options (--security-opt): Set security-related options for the container.
## Logging configuration (--log-driver and --log-opt): Specify logging driver and options

function run_container_basic() {
    local container_name repository tag host_dir privileges devices port_mappings user env_vars run_mode network_mode

    read -p "Enter container name: " container_name
    validate_input "$container_name" || return

    docker inspect "$container_name" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "\033[31m Container $container_name already exists! \033[0m"
        return
    fi

    read -p "Enter image repository: " repository
    validate_input "$repository" || return

    read -p "Enter image tag: " tag
    validate_input "$tag" || return

    host_dir="/home/docker_users/$container_name"
    mkdir -p "$host_dir" || return

    privileges=$(add_privileged_permission)
    devices=$(read_devices)
    port_mappings=$(read_port_mappings)
    env_vars=$(read_environment_variables)
    run_mode=$(choose_run_mode)
    network_mode=$(choose_network_mode)

    read -p "Enter username to run container as (press ENTER to use 'root'): " user
    [[ -z "$user" ]] && user="root"

    docker run $privileges $devices $port_mappings $env_vars $network_mode $run_mode \
        -v "$host_dir:/home/$container_name" --name "$container_name" \
        -u "$user" "$repository":"$tag" /bin/bash
    
    save_container_config "$container_name" "$repository" "$tag" "$host_dir" "$privileges" "$devices" "$port_mappings" "$user" "$env_vars" "$run_mode" "$network_mode"
}

function run_container_free() {
    read -p "Enter container setting: " container_setting
    docker run "$container_setting"
}



function enter_container() {
    read -p "Enter container name: " container_name
    validate_input $container_name

    docker exec -it "$container_name" /bin/bash
    exit 1
}

function start_container() {
    read -p "Enter container name: " container_name
    validate_input $container_name

    docker start -i "$container_name"
}

function stop_container() {
    read -p "Enter container name: " container_name
    validate_input $container_name

    docker stop "$container_name"
}

function remove_container() {
    read -p "Enter container name: " container_name
    validate_input "$container_name" || return

    confirm_operation || return

    docker rm "$container_name"
    rm -rf "/home/docker_users/$container_name"
}

function setting_running_container() {
    local container_name yaml_path

    read -p "Enter the name of the container to reconfigure: " container_name
    validate_input "$container_name" || return

    # Check if the container exists and is running
    if ! docker ps -q -f name=^/${container_name}$; then
        echo "Container ${container_name} does not exist or is not running."
        return
    fi

    yaml_path="/home/docker_users/yaml/${container_name}.yaml"

    if [[ -f "$yaml_path" ]]; then
        echo "Current configuration for ${container_name}:"
        cat "$yaml_path"
    else
        echo "No configuration file found for ${container_name}."
        return
    fi

    echo "Stopping container ${container_name}..."
    confirm_operation || return
    docker stop "$container_name"

    echo "Removing container ${container_name}..."
    confirm_operation || return
    docker rm "$container_name"

    # Re-run the container with new settings
    echo "Re-running container ${container_name} with new settings..."
    run_container_basic "$container_name"
}

# images

function pull_image() {
    echo "Find images here: https://hub.docker.com/search?q=&type=image"

    read -p "Enter image name (exp: ubuntu): " repository
    validate_input $repository

    read -p "Enter image tag (exp: 18.04): " tag
    validate_input $tag

    docker pull "$repository":"$tag"
}

function import_image() {
    read -p "Enter image path (exp: /home/dev/xxx.tar): " image_path
    validate_input $image_path

    read -p "Enter image name (exp: ubuntu18/project_name): " repository
    validate_input $repository

    read -p "Enter image tag (exp: latest / 0.1): " tag
    validate_input $tag

    docker import "$image_path" "$repository":"$tag"
}

function export_image() {
    read -p "Enter container ID: " container_id
    validate_input $container_id

    read -p "Enter saved file name: " file_name
    validate_input $file_name

    local image_dir="/home/docker_users/images"
    if [ -d "$image_dir" ]; then
        echo "$image_dir already exists"
    else
        mkdir -p "$image_dir"
    fi

    docker export "$container_id" >"/home/docker_users/images/$file_name.tar"
}

function remove_image() {
    read -p "Enter image name: " image_name
    validate_input "$image_name" || return

    confirm_operation || return

    docker rmi "$image_name"
}

function configure_docker_for_firewalld() {
    echo "Configuring Docker to work with firewalld..."
    mkdir -p /etc/docker
    echo '{ "iptables": false }' > /etc/docker/daemon.json
    systemctl restart docker
    echo "Docker configured to work with firewalld."
}

function reset_docker_configuration() {
    echo "Resetting Docker configuration..."
    rm -f /etc/docker/daemon.json
    systemctl restart docker
    echo "Docker configuration reset."
}

main_menu() {
    while true; do
        echo -e "${GREEN}********** Docker Management Menu **********${RESET}"
        echo -e "${GREEN} Please select an operation to perform: ${RESET}"
        echo -e "${GREEN} 1.  View Docker Container ID and Details${RESET}"
        echo -e "${GREEN} 2.  Run a Container${RESET}"
        echo -e "${GREEN} 3.  Run a Container Freely${RESET}"
        echo -e "${GREEN} 4.  Enter a Running Container${RESET}"
        echo -e "${GREEN} 5.  Start a Container${RESET}"
        echo -e "${GREEN} 6.  Stop a Container${RESET}"
        echo -e "${GREEN} 7.  Remove a Container${RESET}"
        echo -e "${GREEN} 8.  Setting a Running Container${RESET}"
        echo -e "${GREEN}********************************************${RESET}"
        echo -e "${GREEN}10.  View Docker Images${RESET}"
        echo -e "${GREEN}11.  Pull Docker Image${RESET}"
        echo -e "${GREEN}12.  Import Image from Local File${RESET}"
        echo -e "${GREEN}13.  Export Image to Local File${RESET}"
        echo -e "${GREEN}14.  Remove an Image${RESET}"
        echo -e "${GREEN}********************************************${RESET}"
        echo -e "${GREEN}20.  View Docker Status${RESET}"
        echo -e "${GREEN}21.  Start Docker${RESET}"
        echo -e "${GREEN}22.  Stop Docker${RESET}"
        echo -e "${GREEN}23.  Restart Docker${RESET}"
        echo -e "${GREEN}24.  Set Docker Firewall as Firewalld${RESET}"
        echo -e "${GREEN}25.  Set Docker Firewall as Default${RESET}"
        echo -e "${GREEN}********************************************${RESET}"
        echo -e "${GREEN} 0.  Exit${RESET}"
        echo -e "${GREEN}********************************************${RESET}"

        read -p "Enter the number for the operation: " choice
        case $choice in
        1)
            docker ps -a
            # docker system df
            ;;
        2) run_container_basic ;;
        3) run_container_free ;;
        4) enter_container ;;
        5) start_container ;;
        6) stop_container ;;
        7) remove_container ;;
        8) setting_running_container ;;
        10)
            docker images
            ;;
        11) pull_image ;;
        12) import_image ;;
        13) export_image ;;
        14) remove_image ;;
        20) 
            echo "Docker service status"
            sudo systemctl status docker
            ;;
        21) 
            echo "Docker service starting..."
            sudo systemctl start docker
            ;;
        22) 
            echo "Docker service stopping..."
            sudo systemctl stop docker
            ;;
        23) 
            echo "Restarting Docker service..."
            sudo systemctl restart docker 
            ;;
        24)configure_docker_for_firewalld ;;
        25)reset_docker_configuration ;;
        0) exit 1 ;;
        *) echo "Invalid selection" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

main_menu
#!/bin/bash

function validate_input() {
    if [[ -z "$1" ]]; then
        echo "Input cannot be empty"
        return 1
    fi
    # Add more validation here if needed
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

# 镜像名称和标签：指定要运行的镜像，如 docker run ubuntu:18.04。
# 命令和参数：在容器内执行的命令和参数，如 docker run ubuntu:18.04 /bin/bash。
# 端口映射 (-p 或 --publish)：将容器内的端口映射到宿主机的端口上，如 -p 8080:80。
# 卷挂载 (-v 或 --volume)：将宿主机的文件或目录挂载到容器内，例如 -v /host/path:/container/path。
# 环境变量 (-e 或 --env)：设置容器内的环境变量，例如 -e MY_VAR=value， DATABASE_URL=postgresql://db:5432 通过改变环境变量的值增加容器应用的灵活性和可配置性
# 名称 (--name)：指定容器的名称，便于识别和管理，如 --name mycontainer。
## 网络配置 (--net): 指定容器的网络模式，如 --net=bridge。
## 资源限制：包括内存 (-m 或 --memory) 和 CPU (--cpus) 限制，如 -m 512m 或 --cpus=1.5。
# 交互模式和TTY (-i，-t): -it 通常一起使用，为容器提供一个交互式终端。
# 运行模式：如 --detach 或 -d，使容器在后台运行。
# 用户 (-u 或 --user)：指定运行容器内进程的用户。
# 挂载设备 (--device)：将宿主机的设备挂载到容器内，如 --device=/dev/sda:/dev/xvdc。
## 健康检查 (--health-cmd, --health-interval 等)：配置容器的健康检查。
## 重启策略 (--restart): 设置容器的重启策略，如 --restart=always。
## 安全选项 (--security-opt): 用于设置容器的安全相关选项。
## 日志配置 (--log-driver 和 --log-opt): 指定日志记录的驱动和选项

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
    exit 0
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
        echo -e "\033[32m ********** \033[0m"
        echo -e "\033[32m Please select an operation to perform: \033[0m"
        echo -e "\033[32m 1. View dockers container ID and details \033[0m"
        echo -e "\033[32m 2. Run a container \033[0m"
        echo -e "\033[32m 3. Run a container freely \033[0m"
        echo -e "\033[32m 4. Enter a running container \033[0m"
        echo -e "\033[32m 5. Start a container \033[0m"
        echo -e "\033[32m 6. Stop a container \033[0m"
        echo -e "\033[32m 7. Remove a container \033[0m"
        echo -e "\033[32m 8. Setting a running container \033[0m"
        echo -e "\033[32m ********** \033[0m"
        echo -e "\033[32m 10. View dockers image \033[0m"
        echo -e "\033[32m 11. Pull dockers image \033[0m"
        echo -e "\033[32m 12. Import image from local file \033[0m"
        echo -e "\033[32m 13. Export image to local file \033[0m"
        echo -e "\033[32m 14. Remove an image \033[0m"
        echo -e "\033[32m ********** \033[0m"
        echo -e "\033[32m 20. Status docker \033[0m"
        echo -e "\033[32m 21. Start docker \033[0m"
        echo -e "\033[32m 22. StaStoptus docker \033[0m"
        echo -e "\033[32m 23. Restart docker \033[0m"
        echo -e "\033[32m 24. Set Docker firewall as firewalld\033[0m"
        echo -e "\033[32m 25. Set Docker firewall as default\033[0m"
        echo -e "\033[32m ********** \033[0m"
        echo -e "\033[32m 0. Exit \033[0m"
        echo -e "\033[32m ********** \033[0m"

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
        0) exit 0 ;;
        *) echo "Invalid selection" ;;
        esac
    done
}

main_menu
#!/bin/bash

function validate_input() {
    if [ -z "$1" ]; then
        echo "Input cannot be empty"
        return 1
    fi
}

function run_container_basic() {
    local container_name image_name image_tag port_mapping
    read -p "Enter container name: " container_name
    validate_input $container_name

    docker inspect "$container_name" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "\033[31m Container $container_name already exists! \033[0m"
    fi

    read -p "Enter image repository: " repository
    validate_input $repository

    read -p "Enter image tag: " tag
    validate_input $tag

    local host_dir="/home/docker_users/$container_name"
    if [ -d "$host_dir" ]; then
        echo "$host_dir already exists"
    else
        mkdir -p "$host_dir"
    fi

    local device="/dev/fuse"

    docker run --privileged -it --net=host --cap-add SYS_ADMIN \
        --device "$device" \
        -v "$host_dir:/home/$container_name" --name "$container_name" \
        -u root "$repository":"$tag" /bin/bash
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
    validate_input $container_name

    docker rm "$container_name"
    rm -rf "/home/docker_users/$container_name"

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
    validate_input $image_name

    docker rmi "$image_name"
}

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
    echo -e "\033[32m 8. View dockers image \033[0m"
    echo -e "\033[32m 9. Pull dockers image \033[0m"
    echo -e "\033[32m 10. Import image from local file \033[0m"
    echo -e "\033[32m 11. Export image to local file \033[0m"
    echo -e "\033[32m 12. Remove an image \033[0m"
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
    8)
        docker images
        ;;
    9) pull_image ;;
    10) import_image ;;
    11) export_image ;;
    12) remove_image ;;
    0) exit 0 ;;
    *) echo "Invalid selection" ;;
    esac
done

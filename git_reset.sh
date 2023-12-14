#!/bin/bash

# 获取当前 Git 仓库的远程地址
remote_url=$(git remote -v | awk '/origin.*\(push\)$/ {print $2}')

# 检查 remote_url 是否为空
if [ -z "$remote_url" ]; then
    echo "Error: No remote URL found for 'origin'."
    exit 1
fi

# 可以进一步检查 remote_url 是否为有效的 Git 仓库地址
# 这里仅简单检查 URL 格式
if ! [[ "$remote_url" =~ ^https?:// || "$remote_url" =~ ^git@ ]]; then
    echo "Error: The remote URL '$remote_url' is not a valid URL."
    exit 1
fi

# 移除名为 origin 的远程仓库
git remote rm origin

# 添加新的名为 origin 的远程仓库，并设置为第一步获取的地址
git remote add origin "$remote_url"

# 推送本地分支 master 到远程仓库 origin，并设置为跟踪分支
git push -u origin master

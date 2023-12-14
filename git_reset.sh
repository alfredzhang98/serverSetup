#!/bin/bash

# 加速Git
# https://cloud.tencent.com/developer/article/1835785

# 获取当前 Git 仓库的远程地址
remote_url=$(git remote -v | awk '/origin.*\(push\)$/ {print $2}')

# 检查 remote_url 是否为空
if [ -z "$remote_url" ]; then
    echo "Error: No remote URL found for 'origin'."
    exit 1
fi

# 移除名为 origin 的远程仓库
git remote rm origin

# 添加新的名为 origin 的远程仓库，并设置为第一步获取的地址
git remote add origin "$remote_url"

# 检查是否存在 master 或 main 分支
if git show-ref --verify --quiet refs/heads/master; then
    branch_to_push="master"
elif git show-ref --verify --quiet refs/heads/main; then
    branch_to_push="main"
else
    echo "Error: Neither 'master' nor 'main' branch found."
    exit 1
fi

# 推送选定的分支到远程仓库 origin，并设置为跟踪分支
git push -u origin $branch_to_push

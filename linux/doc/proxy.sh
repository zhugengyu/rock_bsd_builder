#!/bin/bash

# 自动获取 Windows 宿主机 IP
HOST_IP=$(ip route | grep default | awk '{print $3}')
PORT=7890  # 替换为你的代理端口

function set_proxy() {
    # 如果提供了自定义 IP，则使用它
    if [ -n "$2" ]; then
        HOST_IP="$2"
    fi

    export http_proxy="http://${HOST_IP}:${PORT}"
    export https_proxy="http://${HOST_IP}:${PORT}"
    export ALL_PROXY="http://${HOST_IP}:${PORT}"

    echo "代理已启用:"
    echo "http_proxy: $http_proxy"
    echo "https_proxy: $https_proxy"
    echo "ALL_PROXY: $ALL_PROXY"

    # 测试连接
    echo -e "\n正在测试代理连接..."
    curl -I https://www.google.com 2>/dev/null | head -n 1 || echo "代理连接失败。请检查你的设置。"
}

function unset_proxy() {
    unset http_proxy
    unset https_proxy
    unset ALL_PROXY
    echo "代理已禁用"
}

# 根据参数执行操作
case "$1" in
    "on")
        set_proxy "$@"  # 传递所有参数
        ;;
    "off")
        unset_proxy
        ;;
    *)
        echo "用法: source $(basename $0) [on [ip地址] | off]"
        echo "示例: source $(basename $0) on 192.168.1.100"
        echo "      source $(basename $0) off"
        ;;
esac
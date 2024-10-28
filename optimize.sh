#!/bin/bash

# 定义颜色
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
plain='\e[0m'

# 检查root权限
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

# 获取服务器内存大小（MB）
get_memory_size() {
    local mem_total=$(free -m | grep Mem | awk '{print $2}')
    echo $mem_total
}

# 备份配置
backup_configs() {
    echo -e "${green}创建配置备份...${plain}"
    cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d) 2>/dev/null
    cp /etc/security/limits.conf /etc/security/limits.conf.backup.$(date +%Y%m%d) 2>/dev/null
}

# 针对小内存优化（<=2GB）
apply_small_memory_optimizations() {
    cat > /etc/sysctl.conf << EOF
# 基础网络参数优化
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_forward = 1

# TCP缓冲区优化(小内存版)
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 87380 16777216
net.ipv4.tcp_mem = 196608 262144 394240

# 连接优化(小内存版)
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 2048
net.core.netdev_max_backlog = 2048
net.ipv4.tcp_max_tw_buckets = 2000
net.ipv4.tcp_max_orphans = 2048
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000

# TCP keepalive优化
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15

# BBR相关
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

    # 系统限制(小内存版)
    cat > /etc/security/limits.conf << EOF
*               soft    nofile          65535
*               hard    nofile          65535
*               soft    nproc           65535
*               hard    nproc           65535
EOF

    echo "fs.file-max = 65535" >> /etc/sysctl.conf
    echo "fs.inotify.max_user_instances = 4096" >> /etc/sysctl.conf
}

# 针对中等配置优化（2-4GB）
apply_medium_memory_optimizations() {
    cat > /etc/sysctl.conf << EOF
# 基础网络参数优化
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_forward = 1

# TCP缓冲区优化(中等配置版)
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 87380 33554432
net.ipv4.tcp_wmem = 4096 87380 33554432
net.ipv4.tcp_mem = 393216 524288 786432

# 连接优化(中等配置版)
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 4000
net.ipv4.tcp_max_orphans = 8192
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000

# TCP keepalive优化
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# BBR相关
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

    # 系统限制(中等配置版)
    cat > /etc/security/limits.conf << EOF
*               soft    nofile          200000
*               hard    nofile          200000
*               soft    nproc           200000
*               hard    nproc           200000
EOF

    echo "fs.file-max = 200000" >> /etc/sysctl.conf
    echo "fs.inotify.max_user_instances = 8192" >> /etc/sysctl.conf
}

# 针对大内存优化（>4GB）
apply_large_memory_optimizations() {
    cat > /etc/sysctl.conf << EOF
# 基础网络参数优化
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_forward = 1

# TCP缓冲区优化(大内存版)
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 87380 67108864
net.ipv4.tcp_mem = 786432 2097152 67108864
net.ipv4.tcp_window_scaling = 1

# 连接优化(大内存版)
net.ipv4.tcp_max_syn_backlog = 32768
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2

# TIME_WAIT优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535

# TCP keepalive优化
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# BBR相关
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 提高UDP性能
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
EOF

    # 系统限制(大内存版)
    cat > /etc/security/limits.conf << EOF
*               soft    nofile          1000000
*               hard    nofile          1000000
*               soft    nproc           1000000
*               hard    nproc           1000000
EOF

    echo "fs.file-max = 1000000" >> /etc/sysctl.conf
    echo "fs.inotify.max_user_instances = 8192" >> /etc/sysctl.conf
}

# 设置BBR
setup_bbr() {
    echo -e "${yellow}检查并启用BBR...${plain}"
    if ! lsmod | grep -q bbr; then
        modprobe tcp_bbr
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sysctl -p
    fi
}

# 优化网络接口
optimize_network_interface() {
    local MAIN_INTERFACE=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
    
    if [ ! -z "$MAIN_INTERFACE" ]; then
        echo -e "${yellow}优化网络接口: $MAIN_INTERFACE${plain}"
        ip link set $MAIN_INTERFACE txqueuelen 10000 2>/dev/null
        
        # 只在有ethtool的情况下执行
        if command -v ethtool >/dev/null 2>&1; then
            QUEUES=$(ethtool -l $MAIN_INTERFACE 2>/dev/null | grep -i "combined" | head -n1 | awk '{print $2}')
            if [ ! -z "$QUEUES" ] && [ $QUEUES -gt 1 ]; then
                ethtool -L $MAIN_INTERFACE combined $QUEUES 2>/dev/null
            fi
        fi
    fi
}

# 优化DNS（修复了chattr的问题）
optimize_dns() {
    echo -e "${yellow}优化DNS设置...${plain}"
    
    # 备份原始resolv.conf
    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null
    
    # 设置新的DNS服务器
    cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
    
    # 如果系统支持，才使用chattr
    if command -v chattr >/dev/null 2>&1; then
        if [[ -f /etc/resolv.conf && $(lsattr /etc/resolv.conf 2>/dev/null) != *"i"* ]]; then
            chattr +i /etc/resolv.conf 2>/dev/null || true
        fi
    fi
}

# 清理系统缓存
clear_cache() {
    echo -e "${yellow}清理系统缓存...${plain}"
    sync; echo 3 > /proc/sys/vm/drop_caches
    sync; echo 2 > /proc/sys/vm/drop_caches
    sync; echo 1 > /proc/sys/vm/drop_caches
}

# 展示菜单
show_menu() {
    echo -e "
  ${green}VPS性能优化脚本${plain}
  ${green}1.${plain}  自动检测并优化（推荐）
  ${green}2.${plain}  小内存优化方案（<=2GB）
  ${green}3.${plain}  中等配置优化方案（2-4GB）
  ${green}4.${plain}  大内存优化方案（>4GB）
  ${green}5.${plain}  仅设置BBR
  ${green}6.${plain}  查看当前网络配置
  ${green}7.${plain}  恢复默认配置
  ${green}0.${plain}  退出脚本
"
    echo && read -p "请输入选择 [0-7]: " num
}

# 应用优化
apply_optimizations() {
    local mem_size=$1
    backup_configs
    
    if [ $mem_size -le 2048 ]; then
        echo -e "${red}应用小内存优化方案...${plain}"
        apply_small_memory_optimizations
    elif [ $mem_size -le 4096 ]; then
        echo -e "${red}应用中等配置优化方案...${plain}"
        apply_medium_memory_optimizations
    else
        echo -e "${red}应用大内存优化方案...${plain}"
        apply_large_memory_optimizations
    fi
    
    setup_bbr
    optimize_network_interface
    optimize_dns
    clear_cache
    sysctl -p
    
    echo -e "${green}优化完成！${plain}"
}

# 查看当前配置
view_current_config() {
    echo -e "${yellow}当前系统配置：${plain}"
    echo -e "${yellow}内存大小：${plain}$(free -h | grep Mem | awk '{print $2}')"
    echo -e "${yellow}当前TCP拥塞控制算法：${plain}$(sysctl -n net.ipv4.tcp_congestion_control)"
    echo -e "${yellow}当前队列算法：${plain}$(sysctl -n net.core.default_qdisc)"
    echo -e "\n${yellow}重要网络参数：${plain}"

    # 定义参考值数组，包括小、中、大内存的阈值
    declare -A ref_values=(
        ["net.core.rmem_max"]="16777216 33554432 67108864"
        ["net.core.wmem_max"]="16777216 33554432 67108864"
        ["net.ipv4.tcp_max_syn_backlog"]="2048 8192 32768"
        ["net.core.somaxconn"]="2048 8192 32768"
    )

    # 遍历每个参数，显示当前值、参考值和区间判断
    for param in "${!ref_values[@]}"; do
        current_value=$(sysctl -n "$param")
        read -r small_ref medium_ref large_ref <<< "${ref_values[$param]}"

        # 根据当前值与参考值的关系，标注当前配置的区间并高亮
        if (( current_value <= small_ref )); then
            range="${green}小内存优化方案（<=2GB）${plain}"
        elif (( current_value <= medium_ref )); then
            range="${yellow}中等配置优化方案（2-4GB）${plain}"
        elif (( current_value <= large_ref )); then
            range="${red}大内存优化方案（>4GB）${plain}"
        else
            range="${red}超出大内存优化方案参考值${plain}"
        fi

        echo -e "${param} = ${current_value} ${plain}（参考值：小内存: $small_ref, 中等配置: $medium_ref, 大内存: $large_ref，当前配置: ${range}）"
    done
}

# 恢复默认配置
restore_default() {
    local latest_backup=$(ls -t /etc/sysctl.conf.backup.* 2>/dev/null | head -n1)
    if [ ! -z "$latest_backup" ]; then
        cp "$latest_backup" /etc/sysctl.conf
        sysctl -p
        echo -e "${green}已恢复到备份配置：$latest_backup${plain}"
    else
        echo -e "${red}未找到备份配置${plain}"
    fi
}

# 主函数
main() {
    show_menu
    
    case $num in
        1)
            mem_size=$(get_memory_size)
            apply_optimizations $mem_size
            ;;
        2)
            apply_optimizations 2048
            ;;
        3)
            apply_optimizations 4096
            ;;
        4)
            apply_optimizations 8192
            ;;
        5)
            setup_bbr
            ;;
        6)
            view_current_config
            ;;
        7)
            restore_default
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${red}请输入正确的数字 [0-7]${plain}"
            ;;
    esac
    
    # 询问是否重启
    if [[ $num =~ ^[1-4]$ ]]; then
        read -p "需要重启服务器才能使所有优化生效，是否现在重启？[Y/n] " yn
        [ -z "${yn}" ] && yn="y"
        if [[ $yn == [Yy] ]]; then
            echo "服务器重启中..."
            reboot
        else
            echo "请记得稍后手动重启服务器以使所有优化生效"
        fi
    fi  # Closing the if statement correctly
    
    }  # Closing the main function correctly

# 运行主函数
main

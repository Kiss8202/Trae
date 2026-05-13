#!/usr/bin/env bash

# ============================================================
#
#  proxy-toolkit 安装脚本
#
#  支持的协议:
#    - VLESS + Vision + Reality
#    - VMess + WebSocket + TLS (支持路径分流)
#    - Trojan + TLS
#    - Hysteria2
#    - Shadowsocks + ShadowTLSv3
#    - TUIC v5
#    - NaiveProxy
#    - AnyTLS
#    - SOCKS5
#
#  支持的操作系统:
#    - Debian / Ubuntu / Kali
#    - Alpine Linux
#    - CentOS / RHEL / Fedora / AlmaLinux / Rocky Linux
#    - Arch Linux
#    - openSUSE (openSUSE Leap / Tumbleweed)
#
#  架构: amd64 (x86_64), arm64 (aarch64)
#
# ============================================================

# ==================== 版本信息 ====================
VERSION='v1.0.0'
SCRIPT_NAME='proxy-toolkit'

# ==================== 路径配置 ====================
INSTALL_DIR="/etc/proxy-core"
SB_DIR="${INSTALL_DIR}/sing-box"
XRAY_DIR="${INSTALL_DIR}/xray"
ARGO_DIR="/opt/argo"
CONFIG_DIR="${INSTALL_DIR}/config"
LINK_DIR="${CONFIG_DIR}/links"
KEY_FILE="${CONFIG_DIR}/keys.conf"
IP_CONFIG_FILE="${CONFIG_DIR}/ip.conf"
RELAY_FILE="${CONFIG_DIR}/relay.conf"

# 脚本路径
SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")

# 链接文件路径
ALL_LINKS_FILE="${LINK_DIR}/all.txt"
REALITY_LINKS_FILE="${LINK_DIR}/reality.txt"
HYSTERIA2_LINKS_FILE="${LINK_DIR}/hysteria2.txt"
SOCKS5_LINKS_FILE="${LINK_DIR}/socks5.txt"
SHADOWTLS_LINKS_FILE="${LINK_DIR}/shadowtls.txt"
HTTPS_LINKS_FILE="${LINK_DIR}/https.txt"
ANYTLS_LINKS_FILE="${LINK_DIR}/anytls.txt"
TUIC_LINKS_FILE="${LINK_DIR}/tuic.txt"
NAIVE_LINKS_FILE="${LINK_DIR}/naive.txt"
VLESS_LINKS_FILE="${LINK_DIR}/vless.txt"
VMESS_LINKS_FILE="${LINK_DIR}/vmess.txt"
TROJAN_LINKS_FILE="${LINK_DIR}/trojan.txt"
SHADOWSOCKS_LINKS_FILE="${LINK_DIR}/shadowsocks.txt"

# ==================== 全局变量 ====================
# 核心类型
CORE_TYPE="sing-box"  # 默认 sing-box，可切换 xray

# IP 配置
SERVER_IP=""
SERVER_IPV6=""
INBOUND_IP_MODE="dual"   # ipv4, ipv6 或 dual，控制入站监听地址（默认双栈）
OUTBOUND_IP_MODE="dual"  # ipv4, ipv6 或 dual，控制出站连接（默认双栈）

# 中转配置数组
RELAY_TAGS=()        # 中转标签数组
RELAY_JSONS=()       # 中转JSON配置数组
RELAY_DESCS=()       # 中转描述数组

# 节点数组
INBOUND_TAGS=()
INBOUND_PORTS=()
INBOUND_PROTOS=()
INBOUND_RELAY_TAGS=()  # 存储每个节点使用的中转标签，"direct" 表示直连
INBOUND_SNIS=()

# 密钥变量
UUID=""
REALITY_PRIVATE=""
REALITY_PUBLIC=""
SHORT_ID=""
HY2_PASSWORD=""
HY2_PORT=""
HY2_UP_MBPS=""
HY2_DOWN_MBPS=""
HY2_OBFS_ENABLE=""
HY2_OBFS_TYPE=""
HY2_OBFS_PASSWORD=""
HY2_PORT_HOPPING=""
HY2_HOPPING_RANGE=""
HY2_NODE_NAME=""
SS_PASSWORD=""
SHADOWTLS_PASSWORD=""
ANYTLS_PASSWORD=""
SOCKS_USER=""
SOCKS_PASS=""
VLESS_PORT=""
VLESS_SNI=""
VLESS_TRANSFER=""
VLESS_WS_PATH=""
VLESS_WS_HOST=""
VLESS_FLOW=""
VMESS_PORT=""
VMESS_SNI=""
VMESS_TRANSFER=""
VMESS_WS_PATH=""
VMESS_WS_HOST=""
TROJAN_PORT=""
TROJAN_SNI=""
TROJAN_FLOW=""
SS_PORT=""
SS_METHOD=""
HTTP_PORT=""
HTTP_USER=""
HTTP_PASS=""
HTTP_NODE_NAME=""
HTTP_TLS_ENABLE=""
SOCKS5_PORT=""
SOCKS5_NODE_NAME=""
SOCKS5_ENABLE_AUTH=""

# 默认SNI
DEFAULT_SNI="time.is"

# 临时文件清理
TEMP_FILES=()
cleanup_temp_files() {
    for f in "${TEMP_FILES[@]}"; do
        rm -rf "$f" 2>/dev/null
    done
}
trap cleanup_temp_files EXIT INT TERM

# ==================== 系统检测变量 ====================
# 系统检测
ALPINE=0
SYSTEM=""
MAJOR=""
ARCH=$(uname -m)

# 服务类型
SYSTEMD=0
OPENRC=0
INIT_SYS=""

# ==================== 字体颜色 ====================
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
NC='\033[0m'
BOLD='\033[1m'

# ==================== 打印函数 ====================
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ==================== Banner ====================
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}║${GREEN}    ██████╗ ███████╗███████╗██╗   ██╗███╗   ███╗██████╗     ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}    ██╔══██╗██╔════╝██╔════╝██║   ██║████╗ ████║██╔══██╗    ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}    ██║  ██║█████╗  █████╗  ██║   ██║██╔████╔██║██████╔╝    ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}    ██║  ██║██╔══╝  ██╔══╝  ██║   ██║██║╚██╔╝██║██╔══██╗    ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}    ██████╔╝███████╗██║     ╚██████╔╝██║ ╚═╝ ██║██████╔╝    ${CYAN}║${NC}"
    echo -e "${CYAN}║${GREEN}    ╚═════╝ ╚══════╝╚═╝      ╚═════╝ ╚═╝     ╚═╝╚═════╝     ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}║${YELLOW}              Proxy Toolkit ${VERSION}                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}         多协议代理合一 | 开箱即用 | 极简管理              ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ==================== 系统检测 ====================
detect_system() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        SYSTEM="${NAME}"
        MAJOR="${VERSION_ID%%.*}"

        # 标记是否为 Alpine
        if [[ "$ID" == "alpine" ]]; then
            ALPINE=1
        else
            ALPINE=0
        fi
    else
        print_error "无法检测系统"
        exit 1
    fi

    # 架构检测
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            print_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac

    print_success "系统: ${SYSTEM} (${ARCH})"
}

# ==================== 检测服务管理器 ====================
detect_init_system() {
    if [[ $ALPINE -eq 1 ]]; then
        OPENRC=1
        INIT_SYS="openrc"
    elif [[ -d /run/systemd/system ]]; then
        SYSTEMD=1
        INIT_SYS="systemd"
    elif [[ -d /run/openrc ]]; then
        OPENRC=1
        INIT_SYS="openrc"
    else
        # 默认尝试 systemd
        if command -v systemctl &>/dev/null; then
            SYSTEMD=1
            INIT_SYS="systemd"
        else
            print_warning "无法检测服务管理器，使用默认配置"
        fi
    fi

    print_info "服务管理器: ${INIT_SYS:-unknown}"
}

# ==================== 获取服务器 IP ====================
get_ip() {
    print_info "获取服务器 IP 地址..."
    local old_ip="${SERVER_IP}"
    local old_ipv6="${SERVER_IPV6}"

    local ipv4=""
    local ipv6=""

    for service in "ifconfig.me" "api.ipify.org" "ip.sb"; do
        ipv4=$(curl -s4 --connect-timeout 5 "https://${service}" 2>/dev/null)
        [[ -n "$ipv4" && "$ipv4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
        ipv4=""
    done

    for service in "ifconfig.me" "api6.ipify.org" "ip.sb"; do
        ipv6=$(curl -s6 --connect-timeout 5 "https://${service}" 2>/dev/null)
        [[ -n "$ipv6" && "$ipv6" =~ ^[0-9a-fA-F:]+$ ]] && break
        ipv6=""
    done

    echo ""
    if [[ -n "$ipv4" ]]; then
        echo -e "  ${GREEN}检测到 IPv4:${NC} ${ipv4}"
    fi
    if [[ -n "$ipv6" ]]; then
        echo -e "  ${GREEN}检测到 IPv6:${NC} ${ipv6}"
    fi
    echo ""

    if [[ -z "$ipv4" && -z "$ipv6" ]]; then
        print_error "无法获取服务器 IP 地址"
        exit 1
    fi

    if [[ -n "$ipv4" ]]; then
        SERVER_IP="$ipv4"
        SERVER_IPV6="$ipv6"
        if [[ -n "$ipv6" ]]; then
            print_success "检测到双栈网络，默认使用 IPv4: ${SERVER_IP}"
            echo -e "${CYAN}提示: 可在主菜单 [出入站配置] 中切换 IPv6${NC}"
        else
            print_success "使用 IPv4: ${SERVER_IP}"
        fi
    elif [[ -n "$ipv6" ]]; then
        SERVER_IP="$ipv6"
        SERVER_IPV6=""
        [[ -z "$INBOUND_IP_MODE" ]] && INBOUND_IP_MODE="ipv6"
        [[ -z "$OUTBOUND_IP_MODE" ]] && OUTBOUND_IP_MODE="dual"
        print_success "使用 IPv6: ${SERVER_IP}"
        print_info "已自动设置入站为 IPv6，出站为双栈模式"
    fi

    if [[ -n "$old_ip" && "$old_ip" != "$SERVER_IP" ]]; then
        print_warning "服务器 IPv4 已从 ${old_ip} 变更为 ${SERVER_IP}"
        print_info "建议使用主菜单 [5] 重新生成链接文件"
    fi
    if [[ -n "$old_ipv6" && "$old_ipv6" != "$SERVER_IPV6" ]]; then
        print_warning "服务器 IPv6 已从 ${old_ipv6} 变更为 ${SERVER_IPV6}"
    fi
}

# ==================== 服务控制函数 ====================
svc_start() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-service sing-box start 2>/dev/null
    else
        systemctl start sing-box
    fi
}

svc_stop() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-service sing-box stop 2>/dev/null
    else
        systemctl stop sing-box
    fi
}

svc_restart() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-service sing-box restart 2>/dev/null
    else
        systemctl restart sing-box
    fi
}

svc_enable() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-update add sing-box default >/dev/null 2>&1
    else
        systemctl enable sing-box >/dev/null 2>&1
    fi
}

svc_disable() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-update del sing-box default >/dev/null 2>&1
    else
        systemctl disable sing-box >/dev/null 2>&1
    fi
}

svc_is_active() {
    if [[ $ALPINE -eq 1 ]]; then
        rc-service sing-box status 2>/dev/null | grep -q 'started'
    else
        systemctl is-active --quiet sing-box
    fi
}

# ==================== 核心选择 ====================
select_core_type() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              ${GREEN}选择代理核心${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} sing-box (推荐，功能最完整)"
    echo ""
    echo -e "  ${GREEN}[2]${NC} xray"
    echo ""
    read -p "请选择代理核心 (1-2，默认1): " core_choice
    core_choice=${core_choice:-1}

    if [[ "$core_choice" == "2" ]]; then
        CORE_TYPE="xray"
    else
        CORE_TYPE="sing-box"
    fi

    print_success "已选择核心: ${CORE_TYPE}"
}

load_core_type() {
    local core_type_file="${CONFIG_DIR}/core_type.conf"
    if [[ -f "${core_type_file}" ]]; then
        CORE_TYPE=$(cat "${core_type_file}" | tr -d '[:space:]')
        [[ "$CORE_TYPE" != "sing-box" && "$CORE_TYPE" != "xray" ]] && CORE_TYPE="sing-box"
    fi
}

# ==================== 核心安装 ====================

install_core() {
    print_info "开始安装核心: ${CORE_TYPE}"

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        install_singbox
    elif [[ "$CORE_TYPE" == "xray" ]]; then
        install_xray
    else
        print_error "不支持的核心类型: ${CORE_TYPE}"
        return 1
    fi

    return $?
}

install_singbox() {
    local sb_bin="${SB_DIR}/sing-box"
    local version="1.9.4"

    if [[ -f "$sb_bin" ]]; then
        local installed_version=$("$sb_bin" version 2>/dev/null | head -n1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)
        if [[ -n "$installed_version" ]]; then
            print_success "sing-box 已安装 (版本: ${installed_version})"
            print_info "跳过安装，如需升级请使用主菜单 [核心管理] 功能"
            return 0
        fi
    fi

    print_info "正在下载 sing-box ${version}..."

    local download_url="https://github.com/SagerNet/sing-box/releases/download/v${version}/sing-box-${version}-linux-${ARCH}.tar.gz"
    local temp_tar="/tmp/sing-box-${version}.tar.gz"
    TEMP_FILES+=("$temp_tar")

    if ! curl -L --fail --progress-bar -o "$temp_tar" "$download_url" 2>/dev/null; then
        print_error "下载 sing-box 失败"
        return 1
    fi

    mkdir -p "${SB_DIR}"

    if ! tar -xzf "$temp_tar" -C "${SB_DIR}" 2>/dev/null; then
        print_error "解压 sing-box 失败"
        rm -f "$temp_tar"
        return 1
    fi

    local extracted_dir="${SB_DIR}/sing-box-${version}-linux-${ARCH}"
    if [[ -d "$extracted_dir" ]]; then
        mv "${extracted_dir}/sing-box" "$sb_bin" 2>/dev/null
        rm -rf "$extracted_dir"
    fi

    chmod +x "$sb_bin"
    rm -f "$temp_tar"

    if [[ ! -f "$sb_bin" ]]; then
        print_error "sing-box 安装失败"
        return 1
    fi

    local installed_version=$("$sb_bin" version 2>/dev/null | head -n1 | grep -oP 'v\d+\.\d+\.\d+' | head -1)
    print_success "sing-box 安装成功 (版本: ${installed_version:-unknown})"

    setup_service_singbox

    return 0
}

install_xray() {
    local xray_bin="${XRAY_DIR}/xray"
    local version="1.8.6"

    if [[ -f "$xray_bin" ]]; then
        local installed_version=$("$xray_bin" version 2>/dev/null | head -n1 | awk '{print $2}')
        if [[ -n "$installed_version" ]]; then
            print_success "xray 已安装 (版本: ${installed_version})"
            print_info "跳过安装，如需升级请使用主菜单 [核心管理] 功能"
            return 0
        fi
    fi

    print_info "正在下载 xray ${version}..."

    local download_url="https://github.com/XTLS/Xray-core/releases/download/v${version}/Xray-linux-${ARCH}.zip"
    local temp_zip="/tmp/xray-${version}.zip"
    TEMP_FILES+=("$temp_zip")

    if ! curl -L --fail --progress-bar -o "$temp_zip" "$download_url" 2>/dev/null; then
        print_error "下载 xray 失败"
        return 1
    fi

    mkdir -p "${XRAY_DIR}"

    if ! unzip -o "$temp_zip" -d "${XRAY_DIR}" 2>/dev/null; then
        print_error "解压 xray 失败"
        rm -f "$temp_zip"
        return 1
    fi

    chmod +x "$xray_bin"
    rm -f "$temp_zip"

    if [[ ! -f "$xray_bin" ]]; then
        print_error "xray 安装失败"
        return 1
    fi

    local installed_version=$("$xray_bin" version 2>/dev/null | head -n1 | awk '{print $2}')
    print_success "xray 安装成功 (版本: ${installed_version:-unknown})"

    setup_service_xray

    return 0
}

setup_service_singbox() {
    if [[ $ALPINE -eq 1 ]]; then
        cat > /etc/init.d/sing-box <<'EOF'
#!/sbin/openrc-run
name="sing-box"
description="Sing-box Service"
command="${SB_DIR}/sing-box"
command_args="run -c ${CONFIG_DIR}/config.json"
command_background=true
pidfile="/run/${name}.pid"
output_log="/var/log/sing-box.log"
error_log="/var/log/sing-box.log"
EOF
        chmod +x /etc/init.d/sing-box
        rc-update add sing-box default >/dev/null 2>&1
    else
        cat > /etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
ExecStart=${SB_DIR}/sing-box run -c ${CONFIG_DIR}/config.json
Restart=on-failure
RestartSec=5
RestartPreventExitStatus=100

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable sing-box 2>/dev/null
    fi
}

setup_service_xray() {
    if [[ $ALPINE -eq 1 ]]; then
        cat > /etc/init.d/xray <<'EOF'
#!/sbin/openrc-run
name="xray"
description="Xray Service"
command="${XRAY_DIR}/xray"
command_args="run -c ${CONFIG_DIR}/config.json"
command_background=true
pidfile="/run/${name}.pid"
output_log="/var/log/xray.log"
error_log="/var/log/xray.log"
EOF
        chmod +x /etc/init.d/xray
        rc-update add xray default >/dev/null 2>&1
    else
        cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=${XRAY_DIR}/xray run -c ${CONFIG_DIR}/config.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable xray 2>/dev/null
    fi
}

# ==================== 密钥管理 ====================

gen_keys() {
    print_info "开始生成密钥..."

    load_keys_from_file

    if [[ -n "$UUID" && -n "$REALITY_PRIVATE" ]]; then
        print_success "密钥已存在，跳过生成"
        return 0
    fi

    gen_uuid

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        gen_sb_reality_keys
    elif [[ "$CORE_TYPE" == "xray" ]]; then
        gen_xray_reality_keys
    fi

    gen_short_id
    gen_passwords

    save_keys_to_file

    print_success "密钥生成完成"
}

gen_uuid() {
    if [[ -n "$UUID" ]]; then
        return 0
    fi

    if command -v uuidgen &>/dev/null; then
        UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    elif [[ -f /proc/sys/kernel/random/uuid ]]; then
        UUID=$(cat /proc/sys/kernel/random/uuid)
    else
        UUID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/')
    fi

    print_info "UUID: ${UUID}"
}

gen_sb_reality_keys() {
    if [[ -n "$REALITY_PRIVATE" && -n "$REALITY_PUBLIC" ]]; then
        return 0
    fi

    local sb_bin="${SB_DIR}/sing-box"
    if [[ ! -f "$sb_bin" ]]; then
        print_error "sing-box 未安装，无法生成 Reality 密钥"
        return 1
    fi

    local keypair=$("$sb_bin" generate reality-keypair 2>/dev/null)
    if [[ -z "$keypair" ]]; then
        print_error "生成 Reality 密钥失败"
        return 1
    fi

    REALITY_PRIVATE=$(echo "$keypair" | grep -oP 'PrivateKey: \K\S+' | head -1)
    REALITY_PUBLIC=$(echo "$keypair" | grep -oP 'PublicKey: \K\S+' | head -1)

    if [[ -z "$REALITY_PRIVATE" || -z "$REALITY_PUBLIC" ]]; then
        print_error "解析 Reality 密钥失败"
        return 1
    fi

    print_info "sing-box Reality 密钥生成成功"
}

gen_xray_reality_keys() {
    if [[ -n "$REALITY_PRIVATE" && -n "$REALITY_PUBLIC" ]]; then
        return 0
    fi

    local xray_bin="${XRAY_DIR}/xray"
    if [[ ! -f "$xray_bin" ]]; then
        print_error "xray 未安装，无法生成 Reality 密钥"
        return 1
    fi

    local key_output=$("$xray_bin" x25519 2>/dev/null)
    if [[ -z "$key_output" ]]; then
        print_error "生成 X25519 密钥失败"
        return 1
    fi

    REALITY_PRIVATE=$(echo "$key_output" | grep -oP 'Private key: \K\S+' | head -1)
    REALITY_PUBLIC=$(echo "$key_output" | grep -oP 'Public key: \K\S+' | head -1)

    if [[ -z "$REALITY_PRIVATE" || -z "$REALITY_PUBLIC" ]]; then
        print_error "解析 X25519 密钥失败"
        return 1
    fi

    print_info "xray X25519 密钥生成成功"
}

gen_short_id() {
    if [[ -n "$SHORT_ID" ]]; then
        return 0
    fi

    SHORT_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -n 1)
    print_info "Short ID: ${SHORT_ID}"
}

gen_passwords() {
    if [[ -z "$HY2_PASSWORD" ]]; then
        HY2_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
        [[ -z "$HY2_PASSWORD" ]] && HY2_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        print_info "Hysteria2 密码: ${HY2_PASSWORD}"
    fi

    if [[ -z "$SS_PASSWORD" ]]; then
        SS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
        [[ -z "$SS_PASSWORD" ]] && SS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        print_info "Shadowsocks 密码: ${SS_PASSWORD}"
    fi

    if [[ -z "$SHADOWTLS_PASSWORD" ]]; then
        SHADOWTLS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
        [[ -z "$SHADOWTLS_PASSWORD" ]] && SHADOWTLS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        print_info "ShadowTLS 密码: ${SHADOWTLS_PASSWORD}"
    fi

    if [[ -z "$ANYTLS_PASSWORD" ]]; then
        ANYTLS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
        [[ -z "$ANYTLS_PASSWORD" ]] && ANYTLS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        print_info "AnyTLS 密码: ${ANYTLS_PASSWORD}"
    fi

    if [[ -z "$SOCKS_USER" ]]; then
        SOCKS_USER="proxy"
    fi

    if [[ -z "$SOCKS_PASS" ]]; then
        SOCKS_PASS=$(openssl rand -base64 12 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 24)
        [[ -z "$SOCKS_PASS" ]] && SOCKS_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
        print_info "SOCKS5 密码: ${SOCKS_PASS}"
    fi
}

save_keys_to_file() {
    mkdir -p "${CONFIG_DIR}"

    cat > "${KEY_FILE}" <<EOF
UUID="${UUID}"
REALITY_PRIVATE="${REALITY_PRIVATE}"
REALITY_PUBLIC="${REALITY_PUBLIC}"
SHORT_ID="${SHORT_ID}"
HY2_PASSWORD="${HY2_PASSWORD}"
HY2_PORT="${HY2_PORT}"
HY2_UP_MBPS="${HY2_UP_MBPS}"
HY2_DOWN_MBPS="${HY2_DOWN_MBPS}"
HY2_OBFS_ENABLE="${HY2_OBFS_ENABLE}"
HY2_OBFS_TYPE="${HY2_OBFS_TYPE}"
HY2_OBFS_PASSWORD="${HY2_OBFS_PASSWORD}"
HY2_PORT_HOPPING="${HY2_PORT_HOPPING}"
HY2_HOPPING_RANGE="${HY2_HOPPING_RANGE}"
HY2_NODE_NAME="${HY2_NODE_NAME}"
SS_PASSWORD="${SS_PASSWORD}"
SHADOWTLS_PASSWORD="${SHADOWTLS_PASSWORD}"
ANYTLS_PASSWORD="${ANYTLS_PASSWORD}"
SOCKS_USER="${SOCKS_USER}"
SOCKS_PASS="${SOCKS_PASS}"
EOF

    chmod 600 "${KEY_FILE}"
    print_info "密钥已保存到 ${KEY_FILE}"
}

load_keys_from_file() {
    if [[ ! -f "${KEY_FILE}" ]]; then
        return 1
    fi

    source "${KEY_FILE}" 2>/dev/null
    return 0
}

# ==================== Reality 协议配置 ====================

setup_reality() {
    print_info "开始配置 Reality 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               Reality 协议配置${CYAN}                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    local sni_input=""
    echo -e "请输入 SNI 域名 ${YELLOW}(回车默认: www.microsoft.com)${NC}: "
    read -r sni_input
    REALITY_SNI="${sni_input:-www.microsoft.com}"
    print_info "SNI 域名: ${REALITY_SNI}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车默认: 443)${NC}: "
    read -r port_input
    REALITY_PORT="${port_input:-443}"
    print_info "端口: ${REALITY_PORT}"

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="Reality-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"

    echo ""
    echo -e "Short ID ${YELLOW}(回车随机生成)${NC}: "
    read -r short_id_input
    if [[ -z "$short_id_input" ]]; then
        gen_short_id
    else
        SHORT_ID="$short_id_input"
        print_info "Short ID: ${SHORT_ID}"
    fi

    echo ""
    echo -e "请选择 IP 类型:"
    echo -e "  ${GREEN}1${NC}. IPv4"
    echo -e "  ${GREEN}2${NC}. IPv6"
    echo -e "  ${YELLOW}请选择 (回车默认 IPv4): ${NC}"
    read -r ip_type_input
    case "${ip_type_input}" in
        2) REALITY_IP_TYPE="ipv6" ;;
        *) REALITY_IP_TYPE="ipv4" ;;
    esac
    print_info "IP 类型: ${REALITY_IP_TYPE}"

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        sb_setup_reality
    elif [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_reality
    else
        print_error "不支持的核心类型: ${CORE_TYPE}"
        return 1
    fi

    generate_reality_link

    save_keys_to_file

    echo ""
    print_success "Reality 协议配置完成!"
}

sb_setup_reality() {
    print_info "生成 sing-box Reality 配置..."

    local reality_tag="reality-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local server_address
    if [[ "$REALITY_IP_TYPE" == "ipv6" ]]; then
        server_address="[$(get_public_ipv6)]"
    else
        server_address="$(get_public_ipv4)"
    fi

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local flow_type="xtls-rprx-vision"

    local fingerprint
    fingerprint=$(get_random_fingerprint)
    print_info "指纹: ${fingerprint}"

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vless",
    "tag": "${reality_tag}",
    "listen": "::",
    "listen_port": ${REALITY_PORT},
    "users": [
        {
            "uuid": "${UUID}",
            "flow": "${flow_type}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${REALITY_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        },
        "reality": {
            "enabled": true,
            "public_key": "${REALITY_PUBLIC}",
            "short_id": ["${SHORT_ID}"]
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box Reality 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 Reality inbound 配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_reality() {
    print_info "生成 xray Reality 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local server_address
    if [[ "$REALITY_IP_TYPE" == "ipv6" ]]; then
        server_address="$(get_public_ipv6)"
    else
        server_address="$(get_public_ipv4)"
    fi

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local flow_type="xtls-rprx-vision"

    local fingerprint
    fingerprint=$(get_random_fingerprint)
    print_info "指纹: ${fingerprint}"

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vless",
    "port": ${REALITY_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "flow": "${flow_type}"
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
            "show": false,
            "dest": "${REALITY_SNI}:443",
            "serverNames": ["${REALITY_SNI}", "www.apple.com", "www.microsoft.com"],
            "privateKey": "${REALITY_PRIVATE}",
            "shortIds": ["${SHORT_ID}"]
        }
    },
    "tag": "reality-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray Reality 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 Reality inbound 配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_reality_link() {
    print_info "生成 Reality 链接..."

    local server_address
    if [[ "$REALITY_IP_TYPE" == "ipv6" ]]; then
        server_address="[$(get_public_ipv6)]"
    else
        server_address="$(get_public_ipv4)"
    fi

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local fingerprint
    fingerprint=$(get_random_fingerprint)

    local flow_type="xtls-rprx-vision"

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${node_name}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${node_name}"

    local reality_link="vless://${UUID}@${server_address}:${REALITY_PORT}?encryption=none&flow=${flow_type}&security=reality&sni=${REALITY_SNI}&fp=${fingerprint}&pbk=${REALITY_PUBLIC}&sid=${SHORT_ID}&type=tcp#${encoded_name}"

    REALITY_LINKS="${reality_link}"

    echo ""
    echo -e "${GREEN}Reality 链接已生成:${NC}"
    echo "${reality_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== Hysteria2 协议配置 ====================

get_random_port() {
    local min_port=10000
    local max_port=60000
    local port=$((RANDOM % (max_port - min_port + 1) + min_port))
    local counter=0
    while netstat -tuln 2>/dev/null | grep -q ":${port} " && [[ $counter -lt 10 ]]; do
        port=$((RANDOM % (max_port - min_port + 1) + min_port))
        counter=$((counter + 1))
    done
    echo "$port"
}

setup_hysteria2() {
    print_info "开始配置 Hysteria2 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             Hysteria2 协议配置${CYAN}                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r port_input
    if [[ -z "$port_input" ]]; then
        HY2_PORT=$(get_random_port)
    else
        HY2_PORT="$port_input"
    fi
    print_info "端口: ${HY2_PORT}"

    echo ""
    echo -e "请输入密码 ${YELLOW}(回车随机生成)${NC}: "
    read -r password_input
    if [[ -z "$password_input" ]]; then
        if [[ -z "$HY2_PASSWORD" ]]; then
            HY2_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
            [[ -z "$HY2_PASSWORD" ]] && HY2_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi
        print_info "密码: ${HY2_PASSWORD}"
    else
        HY2_PASSWORD="$password_input"
        print_info "密码: ${HY2_PASSWORD}"
    fi

    echo ""
    echo -e "请输入上行带宽 (Mbps) ${YELLOW}(回车默认: 100)${NC}: "
    read -r up_mbps_input
    HY2_UP_MBPS="${up_mbps_input:-100}"
    print_info "上行带宽: ${HY2_UP_MBPS} Mbps"

    echo ""
    echo -e "请输入下行带宽 (Mbps) ${YELLOW}(回车默认: 200)${NC}: "
    read -r down_mbps_input
    HY2_DOWN_MBPS="${down_mbps_input:-200}"
    print_info "下行带宽: ${HY2_DOWN_MBPS} Mbps"

    echo ""
    echo -e "是否启用混淆? ${YELLOW}(回车默认: 是)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是 (推荐，抗审查)"
    echo -e "  ${YELLOW}2${NC}. 否"
    read -r obfs_enable_input
    case "${obfs_enable_input}" in
        2) HY2_OBFS_ENABLE="no" ;;
        *) HY2_OBFS_ENABLE="yes" ;;
    esac

    if [[ "$HY2_OBFS_ENABLE" == "yes" ]]; then
        echo ""
        echo -e "请选择混淆模式:"
        echo -e "  ${GREEN}1${NC}. simple (简单混淆)"
        echo -e "  ${GREEN}2${NC}. http (HTTP 混淆)"
        echo -e "  ${YELLOW}请选择 (回车默认: simple)${NC}: "
        read -r obfs_type_input
        case "${obfs_type_input}" in
            2) HY2_OBFS_TYPE="http" ;;
            *) HY2_OBFS_TYPE="simple" ;;
        esac

        echo ""
        echo -e "请输入混淆密码 ${YELLOW}(回车随机生成)${NC}: "
        read -r obfs_password_input
        if [[ -z "$obfs_password_input" ]]; then
            HY2_OBFS_PASSWORD=$(openssl rand -base64 12 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 24)
            [[ -z "$HY2_OBFS_PASSWORD" ]] && HY2_OBFS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
        else
            HY2_OBFS_PASSWORD="$obfs_password_input"
        fi
        print_info "混淆模式: ${HY2_OBFS_TYPE}"
        print_info "混淆密码: ${HY2_OBFS_PASSWORD}"
    fi

    echo ""
    echo -e "是否启用端口跳跃? ${YELLOW}(回车默认: 否)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是"
    echo -e "  ${YELLOW}2${NC}. 否"
    read -r port_hopping_input
    case "${port_hopping_input}" in
        1) HY2_PORT_HOPPING="yes" ;;
        *) HY2_PORT_HOPPING="no" ;;
    esac

    if [[ "$HY2_PORT_HOPPING" == "yes" ]]; then
        echo ""
        echo -e "请输入跳跃端口范围 ${YELLOW}(格式: 20000-50000, 回车默认: 20000-60000)${NC}: "
        read -r hopping_range_input
        HY2_HOPPING_RANGE="${hopping_range_input:-20000-60000}"
        print_info "跳跃端口范围: ${HY2_HOPPING_RANGE}"
    fi

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="Hysteria2-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"
    HY2_NODE_NAME="$node_name"

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        sb_setup_hysteria2
    elif [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_hysteria2
    else
        print_error "不支持的核心类型: ${CORE_TYPE}"
        return 1
    fi

    generate_hysteria2_link

    save_keys_to_file

    echo ""
    print_success "Hysteria2 协议配置完成!"
}

sb_setup_hysteria2() {
    print_info "生成 sing-box Hysteria2 配置..."

    local hy2_tag="hysteria2-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local obfs_config=""
    if [[ "$HY2_OBFS_ENABLE" == "yes" ]]; then
        if [[ "$HY2_OBFS_TYPE" == "http" ]]; then
            obfs_config=$(cat <<EOF
"obfs": {
    "type": "http",
    "password": "${HY2_OBFS_PASSWORD}"
}
EOF
)
        else
            obfs_config=$(cat <<EOF
"obfs": {
    "type": "simple",
    "password": "${HY2_OBFS_PASSWORD}"
}
EOF
)
        fi
    fi

    local obfs_trailing=""
    local obfs_leading=""
    if [[ -n "$obfs_config" ]]; then
        obfs_leading=","
        obfs_trailing=","
    fi

    local sb_inbound_config
    if [[ -n "$obfs_config" ]]; then
        sb_inbound_config=$(cat <<EOF
{
    "type": "hysteria2",
    "tag": "${hy2_tag}",
    "listen": "::",
    "listen_port": ${HY2_PORT},
    "up_mbps": ${HY2_UP_MBPS},
    "down_mbps": ${HY2_DOWN_MBPS},
    "users": [
        {
            "password": "${HY2_PASSWORD}"
        }
    ],
    ${obfs_config}
    "tls": {
        "enabled": true,
        "alpn": ["h3"]
    }
}
EOF
)
    else
        sb_inbound_config=$(cat <<EOF
{
    "type": "hysteria2",
    "tag": "${hy2_tag}",
    "listen": "::",
    "listen_port": ${HY2_PORT},
    "up_mbps": ${HY2_UP_MBPS},
    "down_mbps": ${HY2_DOWN_MBPS},
    "users": [
        {
            "password": "${HY2_PASSWORD}"
        }
    ],
    "tls": {
        "enabled": true,
        "alpn": ["h3"]
    }
}
EOF
)
    fi

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box Hysteria2 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 Hysteria2 inbound 配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_hysteria2() {
    print_info "生成 xray Hysteria2 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local obfs_settings=""
    if [[ "$HY2_OBFS_ENABLE" == "yes" ]]; then
        if [[ "$HY2_OBFS_TYPE" == "http" ]]; then
            obfs_settings=$(cat <<EOF
"obfs": "http",
"obfsPassword": "${HY2_OBFS_PASSWORD}"
EOF
)
        else
            obfs_settings=$(cat <<EOF
"obfs": "simple",
"obfsPassword": "${HY2_OBFS_PASSWORD}"
EOF
)
        fi
    fi

    local xray_inbound_config
    if [[ -n "$obfs_settings" ]]; then
        xray_inbound_config=$(cat <<EOF
{
    "protocol": "hysteria2",
    "port": ${HY2_PORT},
    "listen": "::",
    "settings": {
        "password": "${HY2_PASSWORD}",
        "up": "${HY2_UP_MBPS}",
        "down": "${HY2_DOWN_MBPS}",
        ${obfs_settings}
    },
    "tag": "hysteria2-in"
}
EOF
)
    else
        xray_inbound_config=$(cat <<EOF
{
    "protocol": "hysteria2",
    "port": ${HY2_PORT},
    "listen": "::",
    "settings": {
        "password": "${HY2_PASSWORD}",
        "up": "${HY2_UP_MBPS}",
        "down": "${HY2_DOWN_MBPS}"
    },
    "tag": "hysteria2-in"
}
EOF
)
    fi

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray Hysteria2 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 Hysteria2 inbound 配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_hysteria2_link() {
    print_info "生成 Hysteria2 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local hy2_link="hysteria2://${HY2_PASSWORD}@${server_address}:${HY2_PORT}?upmbps=${HY2_UP_MBPS}&downmbps=${HY2_DOWN_MBPS}"

    if [[ "$HY2_OBFS_ENABLE" == "yes" ]]; then
        hy2_link+="&obfs=${HY2_OBFS_TYPE}&obfs-password=${HY2_OBFS_PASSWORD}"
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${HY2_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${HY2_NODE_NAME}"

    hy2_link+="#${encoded_name}"

    HYSTERIA2_LINKS="${hy2_link}"

    echo ""
    echo -e "${GREEN}Hysteria2 链接已生成:${NC}"
    echo "${hy2_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== VLESS 协议配置 ====================

setup_vless() {
    print_info "开始配置 VLESS 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               VLESS 协议配置${CYAN}                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请选择传输方式:"
    echo -e "  ${GREEN}1${NC}. TCP + Reality (推荐，抗审查)"
    echo -e "  ${GREEN}2${NC}. WebSocket + TLS"
    echo -e "  ${GREEN}3${NC}. gRPC + TLS"
    echo -e "  ${GREEN}4${NC}. HTTP/2"
    echo -e "  ${YELLOW}请选择 (回车默认: 1)${NC}: "
    read -r transfer_input
    case "${transfer_input}" in
        2) VLESS_TRANSFER="ws" ;;
        3) VLESS_TRANSFER="grpc" ;;
        4) VLESS_TRANSFER="h2" ;;
        *) VLESS_TRANSFER="tcp" ;;
    esac
    print_info "传输方式: ${VLESS_TRANSFER}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r port_input
    if [[ -z "$port_input" ]]; then
        VLESS_PORT=$(get_random_port)
    else
        VLESS_PORT="$port_input"
    fi
    print_info "端口: ${VLESS_PORT}"

    if [[ "$VLESS_TRANSFER" != "tcp" ]]; then
        echo ""
        echo -e "请输入 SNI 域名 ${YELLOW}(回车默认: www.microsoft.com)${NC}: "
        read -r sni_input
        VLESS_SNI="${sni_input:-www.microsoft.com}"
        print_info "SNI 域名: ${VLESS_SNI}"
    fi

    if [[ "$VLESS_TRANSFER" == "ws" ]]; then
        echo ""
        echo -e "请输入 WebSocket 路径 ${YELLOW}(回车默认: /vmess)${NC}: "
        read -r ws_path_input
        VLESS_WS_PATH="${ws_path_input:-/vmess}"
        print_info "WebSocket 路径: ${VLESS_WS_PATH}"

        echo ""
        echo -e "请输入 WebSocket Host ${YELLOW}(回车默认: ${VLESS_SNI})${NC}: "
        read -r ws_host_input
        VLESS_WS_HOST="${ws_host_input:-${VLESS_SNI}}"
        print_info "WebSocket Host: ${VLESS_WS_HOST}"
    fi

    if [[ "$VLESS_TRANSFER" == "tcp" ]]; then
        echo ""
        echo -e "是否启用 Flow ${YELLOW}(xtls-rprx-vision, 回车默认: 是)${NC}: "
        echo -e "  ${GREEN}1${NC}. 是"
        echo -e "  ${GREEN}2${NC}. 否"
        read -r flow_input
        case "${flow_input}" in
            2) VLESS_FLOW="" ;;
            *) VLESS_FLOW="xtls-rprx-vision" ;;
        esac
        if [[ -n "$VLESS_FLOW" ]]; then
            print_info "Flow: ${VLESS_FLOW}"
        else
            print_info "Flow: none"
        fi
    fi

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="VLESS-${VLESS_TRANSFER}-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"
    VLESS_NODE_NAME="$node_name"

    if [[ "$CORE_TYPE" == "xray" ]]; then
        case "${VLESS_TRANSFER}" in
            ws) xray_setup_vless_ws ;;
            grpc) xray_setup_vless_grpc ;;
            h2) xray_setup_vless_h2 ;;
            *) xray_setup_vless_tcp ;;
        esac
    else
        case "${VLESS_TRANSFER}" in
            ws) sb_setup_vless_ws ;;
            grpc) sb_setup_vless_grpc ;;
            h2) sb_setup_vless_h2 ;;
            *) sb_setup_vless_tcp ;;
        esac
    fi

    generate_vless_link

    save_keys_to_file

    echo ""
    print_success "VLESS 协议配置完成!"
}

sb_setup_vless_tcp() {
    print_info "生成 sing-box VLESS + TCP + Reality 配置..."

    local vless_tag="vless-tcp-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)
    print_info "指纹: ${fingerprint}"

    local flow_type="${VLESS_FLOW:-none}"

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vless",
    "tag": "${vless_tag}",
    "listen": "::",
    "listen_port": ${VLESS_PORT},
    "users": [
        {
            "uuid": "${UUID}",
            "flow": "${flow_type}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${DEFAULT_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        },
        "reality": {
            "enabled": true,
            "public_key": "${REALITY_PUBLIC}",
            "short_id": ["${SHORT_ID}"]
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VLESS TCP 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

sb_setup_vless_ws() {
    print_info "生成 sing-box VLESS + WebSocket + TLS 配置..."

    local vless_tag="vless-ws-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vless",
    "tag": "${vless_tag}",
    "listen": "::",
    "listen_port": ${VLESS_PORT},
    "users": [
        {
            "uuid": "${UUID}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${VLESS_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    },
    "transport": {
        "type": "ws",
        "ws": {
            "path": "${VLESS_WS_PATH}",
            "headers": {
                "Host": "${VLESS_WS_HOST}"
            }
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VLESS WS 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

sb_setup_vless_grpc() {
    print_info "生成 sing-box VLESS + gRPC + TLS 配置..."

    local vless_tag="vless-grpc-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vless",
    "tag": "${vless_tag}",
    "listen": "::",
    "listen_port": ${VLESS_PORT},
    "users": [
        {
            "uuid": "${UUID}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${VLESS_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    },
    "transport": {
        "type": "grpc",
        "grpc": {
            "service_name": "GunService"
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VLESS gRPC 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

sb_setup_vless_h2() {
    print_info "生成 sing-box VLESS + HTTP/2 配置..."

    local vless_tag="vless-h2-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vless",
    "tag": "${vless_tag}",
    "listen": "::",
    "listen_port": ${VLESS_PORT},
    "users": [
        {
            "uuid": "${UUID}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${VLESS_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    },
    "transport": {
        "type": "http",
        "http": {
            "path": "/vless",
            "hosts": ["${VLESS_SNI}"]
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VLESS H2 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_vless_tcp() {
    print_info "生成 xray VLESS + TCP + Reality 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)
    print_info "指纹: ${fingerprint}"

    local flow_type="${VLESS_FLOW:-none}"

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vless",
    "port": ${VLESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "flow": "${flow_type}"
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
            "show": false,
            "dest": "${DEFAULT_SNI}:443",
            "serverNames": ["${DEFAULT_SNI}", "www.apple.com", "www.microsoft.com"],
            "privateKey": "${REALITY_PRIVATE}",
            "shortIds": ["${SHORT_ID}"]
        }
    },
    "tag": "vless-tcp-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VLESS TCP 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

xray_setup_vless_ws() {
    print_info "生成 xray VLESS + WebSocket + TLS 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vless",
    "port": ${VLESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "alterId": 0
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${VLESS_SNI}",
            "fingerprint": "${fingerprint}"
        },
        "wsSettings": {
            "path": "${VLESS_WS_PATH}",
            "headers": {
                "Host": "${VLESS_WS_HOST}"
            }
        }
    },
    "tag": "vless-ws-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VLESS WS 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

xray_setup_vless_grpc() {
    print_info "生成 xray VLESS + gRPC + TLS 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vless",
    "port": ${VLESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "alterId": 0
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "grpc",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${VLESS_SNI}",
            "fingerprint": "${fingerprint}"
        },
        "grpcSettings": {
            "serviceName": "GunService"
        }
    },
    "tag": "vless-grpc-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VLESS gRPC 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

xray_setup_vless_h2() {
    print_info "生成 xray VLESS + HTTP/2 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vless",
    "port": ${VLESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "alterId": 0
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "http",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${VLESS_SNI}",
            "fingerprint": "${fingerprint}",
            "alpn": ["h2"]
        },
        "httpSettings": {
            "path": "/vless",
            "host": ["${VLESS_SNI}"]
        }
    },
    "tag": "vless-h2-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VLESS H2 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_vless_link() {
    print_info "生成 VLESS 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)
    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${VLESS_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${VLESS_NODE_NAME}"

    local vless_link=""

    case "${VLESS_TRANSFER}" in
        ws)
            vless_link="vless://${UUID}@${server_address}:${VLESS_PORT}?encryption=none&flow=&security=tls&sni=${VLESS_SNI}&fp=${fingerprint}&type=ws&host=${VLESS_WS_HOST}&path=${VLESS_WS_PATH}#${encoded_name}"
            ;;
        grpc)
            vless_link="vless://${UUID}@${server_address}:${VLESS_PORT}?encryption=none&flow=&security=tls&sni=${VLESS_SNI}&fp=${fingerprint}&type=grpc&serviceName=GunService#${encoded_name}"
            ;;
        h2)
            vless_link="vless://${UUID}@${server_address}:${VLESS_PORT}?encryption=none&flow=&security=tls&sni=${VLESS_SNI}&fp=${fingerprint}&type=http&path=/vless#${encoded_name}"
            ;;
        tcp)
            if [[ -n "$VLESS_FLOW" ]]; then
                vless_link="vless://${UUID}@${server_address}:${VLESS_PORT}?encryption=none&flow=${VLESS_FLOW}&security=reality&sni=${DEFAULT_SNI}&fp=${fingerprint}&pbk=${REALITY_PUBLIC}&sid=${SHORT_ID}&type=tcp#${encoded_name}"
            else
                vless_link="vless://${UUID}@${server_address}:${VLESS_PORT}?encryption=none&flow=&security=reality&sni=${DEFAULT_SNI}&fp=${fingerprint}&pbk=${REALITY_PUBLIC}&sid=${SHORT_ID}&type=tcp#${encoded_name}"
            fi
            ;;
    esac

    VLESS_LINKS="${vless_link}"

    echo ""
    echo -e "${GREEN}VLESS 链接已生成:${NC}"
    echo "${vless_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== VMess 协议配置 ====================

setup_vmess() {
    print_info "开始配置 VMess 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               VMess 协议配置${CYAN}                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}提示: VMess 主要用于兼容老客户端${NC}"
    echo ""

    echo -e "请选择传输方式:"
    echo -e "  ${GREEN}1${NC}. TCP (基础)"
    echo -e "  ${GREEN}2${NC}. WebSocket + TLS (推荐)"
    echo -e "  ${YELLOW}请选择 (回车默认: 2)${NC}: "
    read -r transfer_input
    case "${transfer_input}" in
        1) VMESS_TRANSFER="tcp" ;;
        *) VMESS_TRANSFER="ws" ;;
    esac
    print_info "传输方式: ${VMESS_TRANSFER}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r port_input
    if [[ -z "$port_input" ]]; then
        VMESS_PORT=$(get_random_port)
    else
        VMESS_PORT="$port_input"
    fi
    print_info "端口: ${VMESS_PORT}"

    echo ""
    echo -e "请输入 SNI 域名 ${YELLOW}(回车默认: www.microsoft.com)${NC}: "
    read -r sni_input
    VMESS_SNI="${sni_input:-www.microsoft.com}"
    print_info "SNI 域名: ${VMESS_SNI}"

    if [[ "$VMESS_TRANSFER" == "ws" ]]; then
        echo ""
        echo -e "请输入 WebSocket 路径 ${YELLOW}(回车默认: /vmess)${NC}: "
        read -r ws_path_input
        VMESS_WS_PATH="${ws_path_input:-/vmess}"
        print_info "WebSocket 路径: ${VMESS_WS_PATH}"

        echo ""
        echo -e "请输入 WebSocket Host ${YELLOW}(回车默认: ${VMESS_SNI})${NC}: "
        read -r ws_host_input
        VMESS_WS_HOST="${ws_host_input:-${VMESS_SNI}}"
        print_info "WebSocket Host: ${VMESS_WS_HOST}"
    fi

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="VMess-${VMESS_TRANSFER}-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"
    VMESS_NODE_NAME="$node_name"

    if [[ "$CORE_TYPE" == "xray" ]]; then
        case "${VMESS_TRANSFER}" in
            ws) xray_setup_vmess_ws ;;
            *) xray_setup_vmess_tcp ;;
        esac
    else
        case "${VMESS_TRANSFER}" in
            ws) sb_setup_vmess_ws ;;
            *) sb_setup_vmess_tcp ;;
        esac
    fi

    generate_vmess_link

    save_keys_to_file

    echo ""
    print_success "VMess 协议配置完成!"
}

sb_setup_vmess_tcp() {
    print_info "生成 sing-box VMess + TCP 配置..."

    local vmess_tag="vmess-tcp-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vmess",
    "tag": "${vmess_tag}",
    "listen": "::",
    "listen_port": ${VMESS_PORT},
    "users": [
        {
            "uuid": "${UUID}",
            "alterId": 0
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${VMESS_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VMess TCP 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

sb_setup_vmess_ws() {
    print_info "生成 sing-box VMess + WebSocket + TLS 配置..."

    local vmess_tag="vmess-ws-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "vmess",
    "tag": "${vmess_tag}",
    "listen": "::",
    "listen_port": ${VMESS_PORT},
    "users": [
        {
            "uuid": "${UUID}",
            "alterId": 0
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${VMESS_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    },
    "transport": {
        "type": "ws",
        "ws": {
            "path": "${VMESS_WS_PATH}",
            "headers": {
                "Host": "${VMESS_WS_HOST}"
            }
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box VMess WS 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_vmess_tcp() {
    print_info "生成 xray VMess + TCP 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vmess",
    "port": ${VMESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "alterId": 0
            }
        ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${VMESS_SNI}",
            "fingerprint": "${fingerprint}"
        }
    },
    "tag": "vmess-tcp-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VMess TCP 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

xray_setup_vmess_ws() {
    print_info "生成 xray VMess + WebSocket + TLS 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "vmess",
    "port": ${VMESS_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "id": "${UUID}",
                "alterId": 0
            }
        ]
    },
    "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${VMESS_SNI}",
            "fingerprint": "${fingerprint}"
        },
        "wsSettings": {
            "path": "${VMESS_WS_PATH}",
            "headers": {
                "Host": "${VMESS_WS_HOST}"
            }
        }
    },
    "tag": "vmess-ws-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray VMess WS 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_vmess_link() {
    print_info "生成 VMess 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local add_json=$(cat <<EOF
{
    "v": "2",
    "ps": "${VMESS_NODE_NAME}",
    "add": "${server_address}",
    "port": "${VMESS_PORT}",
    "id": "${UUID}",
    "aid": "0",
    "net": "${VMESS_TRANSFER}",
    "type": "none",
    "host": "${VMESS_WS_HOST}",
    "path": "${VMESS_WS_PATH}",
    "tls": "tls",
    "sni": "${VMESS_SNI}",
    "fp": "${fingerprint}"
}
EOF
)

    local vmess_base64=$(echo "${add_json}" | base64 -w 0 2>/dev/null)
    [[ -z "$vmess_base64" ]] && vmess_base64=$(echo "${add_json}" | base64 | tr -d '\n')

    local vmess_link="vmess://${vmess_base64}"

    VMESS_LINKS="${vmess_link}"

    echo ""
    echo -e "${GREEN}VMess 链接已生成:${NC}"
    echo "${vmess_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== Trojan 协议配置 ====================

setup_trojan() {
    print_info "开始配置 Trojan 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               Trojan 协议配置${CYAN}                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请输入密码 ${YELLOW}(回车使用 UUID)${NC}: "
    read -r password_input
    if [[ -z "$password_input" ]]; then
        TROJAN_PASSWORD="${UUID}"
    else
        TROJAN_PASSWORD="$password_input"
    fi
    print_info "密码: ${TROJAN_PASSWORD}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r port_input
    if [[ -z "$port_input" ]]; then
        TROJAN_PORT=$(get_random_port)
    else
        TROJAN_PORT="$port_input"
    fi
    print_info "端口: ${TROJAN_PORT}"

    echo ""
    echo -e "请输入 SNI 域名 ${YELLOW}(回车默认: www.microsoft.com)${NC}: "
    read -r sni_input
    TROJAN_SNI="${sni_input:-www.microsoft.com}"
    print_info "SNI 域名: ${TROJAN_SNI}"

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="Trojan-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"
    TROJAN_NODE_NAME="$node_name"

    if [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_trojan
    else
        sb_setup_trojan
    fi

    generate_trojan_link

    save_keys_to_file

    echo ""
    print_success "Trojan 协议配置完成!"
}

sb_setup_trojan() {
    print_info "生成 sing-box Trojan 配置..."

    local trojan_tag="trojan-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local sb_inbound_config=$(cat <<EOF
{
    "type": "trojan",
    "tag": "${trojan_tag}",
    "listen": "::",
    "listen_port": ${TROJAN_PORT},
    "users": [
        {
            "password": "${TROJAN_PASSWORD}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${TROJAN_SNI}",
        "utls": {
            "enabled": true,
            "fingerprint": "${fingerprint}"
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box Trojan 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_trojan() {
    print_info "生成 xray Trojan 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local fingerprint=$(get_random_fingerprint)

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "trojan",
    "port": ${TROJAN_PORT},
    "listen": "::",
    "settings": {
        "clients": [
            {
                "password": "${TROJAN_PASSWORD}",
                "level": 0
            }
        ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${TROJAN_SNI}",
            "fingerprint": "${fingerprint}"
        }
    },
    "tag": "trojan-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray Trojan 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_trojan_link() {
    print_info "生成 Trojan 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${TROJAN_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${TROJAN_NODE_NAME}"

    local trojan_link="trojan://${TROJAN_PASSWORD}@${server_address}:${TROJAN_PORT}?sni=${TROJAN_SNI}#${encoded_name}"

    TROJAN_LINKS="${trojan_link}"

    echo ""
    echo -e "${GREEN}Trojan 链接已生成:${NC}"
    echo "${trojan_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== Shadowsocks 协议配置 ====================

setup_shadowsocks() {
    print_info "开始配置 Shadowsocks 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             Shadowsocks 协议配置${CYAN}                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请选择加密方式:"
    echo -e "  ${GREEN}1${NC}. 2022-blake3-aes-256-gcm (推荐)"
    echo -e "  ${GREEN}2${NC}. 2022-blake3-chacha20-poly1305"
    echo -e "  ${YELLOW}请选择 (回车默认: 1)${NC}: "
    read -r method_input
    case "${method_input}" in
        2) SS_METHOD="2022-blake3-chacha20-poly1305" ;;
        *) SS_METHOD="2022-blake3-aes-256-gcm" ;;
    esac
    print_info "加密方式: ${SS_METHOD}"

    echo ""
    echo -e "请输入密码 ${YELLOW}(回车随机生成)${NC}: "
    read -r password_input
    if [[ -z "$password_input" ]]; then
        if [[ -z "$SS_PASSWORD" ]]; then
            SS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
            [[ -z "$SS_PASSWORD" ]] && SS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi
        print_info "密码: ${SS_PASSWORD}"
    else
        SS_PASSWORD="$password_input"
        print_info "密码: ${SS_PASSWORD}"
    fi

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r port_input
    if [[ -z "$port_input" ]]; then
        SS_PORT=$(get_random_port)
    else
        SS_PORT="$port_input"
    fi
    print_info "端口: ${SS_PORT}"

    echo ""
    echo -e "请输入节点名称: "
    read -r node_name
    if [[ -z "$node_name" ]]; then
        node_name="Shadowsocks-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${node_name}"
    SS_NODE_NAME="$node_name"

    if [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_shadowsocks
    else
        sb_setup_shadowsocks
    fi

    generate_shadowsocks_link

    save_keys_to_file

    echo ""
    print_success "Shadowsocks 协议配置完成!"
}

sb_setup_shadowsocks() {
    print_info "生成 sing-box Shadowsocks 配置..."

    local ss_tag="shadowsocks-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local ss_method_prefix=""
    local ss_method_cipher=""
    case "${SS_METHOD}" in
        *aes*)
            ss_method_prefix="2022-"
            ss_method_cipher="aes-256-gcm"
            ;;
        *)
            ss_method_prefix="2022-"
            ss_method_cipher="chacha20-poly1305"
            ;;
    esac

    local password_part=$(echo -n "${SS_PASSWORD}" | fold -w 32 | head -n 1)
    if [[ ${#SS_PASSWORD} -lt 32 ]]; then
        password_part="${SS_PASSWORD}$(printf '%0.s0' $(seq 1 $((32 - ${#SS_PASSWORD}))))"
    fi

    local sb_inbound_config=$(cat <<EOF
{
    "type": "shadowsocks",
    "tag": "${ss_tag}",
    "listen": "::",
    "listen_port": ${SS_PORT},
    "method": "${SS_METHOD}",
    "password": "${SS_PASSWORD}"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box Shadowsocks 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_shadowsocks() {
    print_info "生成 xray Shadowsocks 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local xray_inbound_config=$(cat <<EOF
{
    "protocol": "shadowsocks",
    "port": ${SS_PORT},
    "listen": "::",
    "settings": {
        "method": "${SS_METHOD}",
        "password": "${SS_PASSWORD}",
        "network": "tcp,udp"
    },
    "tag": "shadowsocks-in"
}
EOF
)

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray Shadowsocks 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_shadowsocks_link() {
    print_info "生成 Shadowsocks 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SS_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${SS_NODE_NAME}"

    local user_part="${SS_METHOD}:${SS_PASSWORD}"
    local ss_base64=$(echo -n "${user_part}@${server_address}:${SS_PORT}" | base64 -w 0 2>/dev/null)
    [[ -z "$ss_base64" ]] && ss_base64=$(echo -n "${user_part}@${server_address}:${SS_PORT}" | base64 | tr -d '\n')

    local ss_link="ss://${ss_base64}#${encoded_name}"

    SHADOWSOCKS_LINKS="${ss_link}"

    echo ""
    echo -e "${GREEN}Shadowsocks 链接已生成:${NC}"
    echo "${ss_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== ShadowTLS 协议配置 ====================

setup_shadowtls() {
    print_info "开始配置 ShadowTLS 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             ShadowTLS 协议配置${CYAN}                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}提示: ShadowTLS 需要两个端口 (ShadowTLS 外部端口 + Shadowsocks 内部端口)${NC}"
    echo ""

    echo -e "请输入 ShadowTLS 外部端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r shadowtls_port_input
    if [[ -z "$shadowtls_port_input" ]]; then
        SHADOWTLS_PORT=$(get_random_port)
    else
        SHADOWTLS_PORT="$shadowtls_port_input"
    fi
    print_info "ShadowTLS 端口: ${SHADOWTLS_PORT}"

    local ss_internal_port
    echo -e "请输入 Shadowsocks 内部端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r ss_internal_input
    if [[ -z "$ss_internal_input" ]]; then
        ss_internal_port=$(get_random_port)
    else
        ss_internal_port="$ss_internal_input"
    fi
    print_info "Shadowsocks 内部端口: ${ss_internal_port}"

    echo ""
    echo -e "请选择 Shadowsocks 加密方式:"
    echo -e "  ${GREEN}1${NC}. 2022-blake3-aes-256-gcm (推荐)"
    echo -e "  ${GREEN}2${NC}. 2022-blake3-chacha20-poly1305"
    echo -e "  ${YELLOW}请选择 (回车默认: 1)${NC}: "
    read -r shadowtls_method_input
    case "${shadowtls_method_input}" in
        2) SHADOWTLS_SS_METHOD="2022-blake3-chacha20-poly1305" ;;
        *) SHADOWTLS_SS_METHOD="2022-blake3-aes-256-gcm" ;;
    esac
    print_info "Shadowsocks 加密方式: ${SHADOWTLS_SS_METHOD}"

    echo ""
    echo -e "请输入密码 ${YELLOW}(回车随机生成)${NC}: "
    read -r shadowtls_password_input
    if [[ -z "$shadowtls_password_input" ]]; then
        if [[ -z "$SHADOWTLS_PASSWORD" ]]; then
            SHADOWTLS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
            [[ -z "$SHADOWTLS_PASSWORD" ]] && SHADOWTLS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi
        print_info "密码: ${SHADOWTLS_PASSWORD}"
    else
        SHADOWTLS_PASSWORD="$shadowtls_password_input"
        print_info "密码: ${SHADOWTLS_PASSWORD}"
    fi

    echo ""
    echo -e "是否启用 Strict Mode? ${YELLOW}(回车默认: 否)${NC}: "
    echo -e "  ${GREEN}1${NC}. 否 (推荐)"
    echo -e "  ${GREEN}2${NC}. 是"
    read -r strict_mode_input
    case "${strict_mode_input}" in
        2) SHADOWTLS_STRICT_MODE="true" ;;
        *) SHADOWTLS_STRICT_MODE="false" ;;
    esac
    print_info "Strict Mode: ${SHADOWTLS_STRICT_MODE}"

    echo ""
    echo -e "请输入节点名称: "
    read -r shadowtls_node_name
    if [[ -z "$shadowtls_node_name" ]]; then
        shadowtls_node_name="ShadowTLS-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${shadowtls_node_name}"
    SHADOWTLS_NODE_NAME="$shadowtls_node_name"

    SHADOWTLS_SS_INTERNAL_PORT="$ss_internal_port"

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        sb_setup_shadowtls
    else
        print_warning "ShadowTLS 主要支持 sing-box，将使用 sing-box 配置"
        sb_setup_shadowtls
    fi

    generate_shadowtls_link

    save_keys_to_file

    echo ""
    print_success "ShadowTLS 协议配置完成!"
}

sb_setup_shadowtls() {
    print_info "生成 sing-box ShadowTLS 配置..."

    local shadowtls_tag="shadowtls-in"
    local ss_tag="shadowtls-ss-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local sb_inbound_configs=$(cat <<EOF
[
    {
        "type": "shadowtls",
        "tag": "${shadowtls_tag}",
        "listen": "::",
        "listen_port": ${SHADOWTLS_PORT},
        "handshake": {
            "server": "127.0.0.1",
            "port": ${SHADOWTLS_SS_INTERNAL_PORT},
            "version": 3
        },
        "strict_mode": ${SHADOWTLS_STRICT_MODE},
        "users": [
            {
                "password": "${SHADOWTLS_PASSWORD}"
            }
        ],
        "receive_window_conn": 8388608,
        "receive_window": 8388608,
        "cache": 8388608
    },
    {
        "type": "shadowsocks",
        "tag": "${ss_tag}",
        "listen": "127.0.0.1",
        "listen_port": ${SHADOWTLS_SS_INTERNAL_PORT},
        "method": "${SHADOWTLS_SS_METHOD}",
        "password": "${SHADOWTLS_PASSWORD}"
    }
]
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_configs}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="${sb_inbound_configs}"
        else
            new_inbounds=$(jq ".inbounds + ${sb_inbound_configs}" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box ShadowTLS 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 ShadowTLS inbound 配置"
        echo "${sb_inbound_configs}"
    fi

    return 0
}

generate_shadowtls_link() {
    print_info "生成 ShadowTLS 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SHADOWTLS_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${SHADOWTLS_NODE_NAME}"

    local shadowtls_link="shadowtls://${SHADOWTLS_PASSWORD}@${server_address}:${SHADOWTLS_PORT}?fp=chrome&name=${encoded_name}#${encoded_name}"

    local ss_encoded_name
    ss_encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SHADOWTLS_NODE_NAME}-SS'))" 2>/dev/null)
    [[ -z "$ss_encoded_name" ]] && ss_encoded_name="${SHADOWTLS_NODE_NAME}-SS"

    local user_part="${SHADOWTLS_SS_METHOD}:${SHADOWTLS_PASSWORD}"
    local ss_base64=$(echo -n "${user_part}@127.0.0.1:${SHADOWTLS_SS_INTERNAL_PORT}" | base64 -w 0 2>/dev/null)
    [[ -z "$ss_base64" ]] && ss_base64=$(echo -n "${user_part}@127.0.0.1:${SHADOWTLS_SS_INTERNAL_PORT}" | base64 | tr -d '\n')
    local ss_link="ss://${ss_base64}#${ss_encoded_name}"

    SHADOWTLS_LINKS="${shadowtls_link}
${ss_link}"

    echo ""
    echo -e "${GREEN}ShadowTLS 链接已生成:${NC}"
    echo "${shadowtls_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
    echo -e "${CYAN}Shadowsocks 内部链接 (用于配合 ShadowTLS):${NC}"
    echo "${ss_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== AnyTLS 协议配置 ====================

setup_anytls() {
    print_info "开始配置 AnyTLS 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               AnyTLS 协议配置${CYAN}                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}提示: AnyTLS 支持自签名证书，推荐使用域名${NC}"
    echo ""

    echo -e "请输入域名/SNI ${YELLOW}(回车默认: ${DEFAULT_SNI})${NC}: "
    read -r anytls_sni_input
    ANYTLS_SNI="${anytls_sni_input:-${DEFAULT_SNI}}"
    print_info "域名/SNI: ${ANYTLS_SNI}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r anytls_port_input
    if [[ -z "$anytls_port_input" ]]; then
        ANYTLS_PORT=$(get_random_port)
    else
        ANYTLS_PORT="$anytls_port_input"
    fi
    print_info "端口: ${ANYTLS_PORT}"

    echo ""
    echo -e "请输入密码 ${YELLOW}(回车使用已有密码或随机生成)${NC}: "
    read -r anytls_password_input
    if [[ -z "$anytls_password_input" ]]; then
        if [[ -z "$ANYTLS_PASSWORD" ]]; then
            ANYTLS_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 32)
            [[ -z "$ANYTLS_PASSWORD" ]] && ANYTLS_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
        fi
        print_info "密码: ${ANYTLS_PASSWORD}"
    else
        ANYTLS_PASSWORD="$anytls_password_input"
        print_info "密码: ${ANYTLS_PASSWORD}"
    fi

    echo ""
    echo -e "请选择指纹:"
    echo -e "  ${GREEN}1${NC}. chrome (推荐)"
    echo -e "  ${GREEN}2${NC}. firefox"
    echo -e "  ${GREEN}3${NC}. safari"
    echo -e "  ${GREEN}4${NC}. ios"
    echo -e "  ${GREEN}5${NC}. android"
    echo -e "  ${GREEN}6${NC}. random"
    echo -e "  ${YELLOW}请选择 (回车默认: 1)${NC}: "
    read -r anytls_fp_input
    case "${anytls_fp_input}" in
        2) ANYTLS_FP="firefox" ;;
        3) ANYTLS_FP="safari" ;;
        4) ANYTLS_FP="ios" ;;
        5) ANYTLS_FP="android" ;;
        6) ANYTLS_FP="random" ;;
        *) ANYTLS_FP="chrome" ;;
    esac
    print_info "指纹: ${ANYTLS_FP}"

    echo ""
    echo -e "是否跳过证书验证? ${YELLOW}(回车默认: 是)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是 (自签名证书需要跳过验证)"
    echo -e "  ${GREEN}2${NC}. 否"
    read -r anytls_insecure_input
    case "${anytls_insecure_input}" in
        2) ANYTLS_INSECURE="0" ;;
        *) ANYTLS_INSECURE="1" ;;
    esac
    print_info "跳过证书验证: ${ANYTLS_INSECURE}"

    echo ""
    echo -e "请输入节点名称: "
    read -r anytls_node_name
    if [[ -z "$anytls_node_name" ]]; then
        anytls_node_name="AnyTLS-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${anytls_node_name}"
    ANYTLS_NODE_NAME="$anytls_node_name"

    gen_cert_for_anytls "${ANYTLS_SNI}"

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        sb_setup_anytls
    else
        print_warning "AnyTLS 主要支持 sing-box，将使用 sing-box 配置"
        sb_setup_anytls
    fi

    generate_anytls_link

    save_keys_to_file

    echo ""
    print_success "AnyTLS 协议配置完成!"
}

gen_cert_for_anytls() {
    local domain="$1"
    local cert_dir="${CONFIG_DIR}/certs"
    local cert_file="${cert_dir}/${domain}.crt"
    local key_file="${cert_dir}/${domain}.key"

    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        print_info "证书已存在: ${domain}"
        return 0
    fi

    mkdir -p "${cert_dir}"

    print_info "为 ${domain} 生成自签名证书..."

    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -subj "/CN=${domain}" \
        2>/dev/null

    if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
        print_error "证书生成失败"
        return 1
    fi

    chmod 600 "$key_file"
    chmod 644 "$cert_file"

    print_success "证书生成完成: ${cert_file}"
    return 0
}

sb_setup_anytls() {
    print_info "生成 sing-box AnyTLS 配置..."

    local anytls_tag="anytls-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local cert_file="${CONFIG_DIR}/certs/${ANYTLS_SNI}.crt"
    local key_file="${CONFIG_DIR}/certs/${ANYTLS_SNI}.key"

    if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
        print_error "证书文件不存在，请先生成证书"
        return 1
    fi

    local sb_inbound_config=$(cat <<EOF
{
    "type": "anytls",
    "tag": "${anytls_tag}",
    "listen": "::",
    "listen_port": ${ANYTLS_PORT},
    "users": [
        {
            "password": "${ANYTLS_PASSWORD}"
        }
    ],
    "tls": {
        "enabled": true,
        "server_name": "${ANYTLS_SNI}",
        "certificate": "${cert_file}",
        "key": "${key_file}",
        "utls": {
            "enabled": true,
            "fingerprint": "${ANYTLS_FP}"
        }
    }
}
EOF
)

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box AnyTLS 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 AnyTLS inbound 配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

generate_anytls_link() {
    print_info "生成 AnyTLS 链接..."

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${ANYTLS_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${ANYTLS_NODE_NAME}"

    local anytls_link="anytls://${ANYTLS_PASSWORD}@${ANYTLS_SNI}:${ANYTLS_PORT}?security=tls&fp=${ANYTLS_FP}&insecure=${ANYTLS_INSECURE}#${encoded_name}"

    ANYTLS_LINKS="${anytls_link}"

    echo ""
    echo -e "${GREEN}AnyTLS 链接已生成:${NC}"
    echo "${anytls_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== SOCKS5 协议配置 ====================

setup_socks5() {
    print_info "开始配置 SOCKS5 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               SOCKS5 协议配置${CYAN}                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r socks5_port_input
    if [[ -z "$socks5_port_input" ]]; then
        SOCKS5_PORT=$(get_random_port)
    else
        SOCKS5_PORT="$socks5_port_input"
    fi
    print_info "端口: ${SOCKS5_PORT}"

    echo ""
    echo -e "是否启用用户认证? ${YELLOW}(回车默认: 是)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是 (推荐)"
    echo -e "  ${GREEN}2${NC}. 否"
    read -r socks5_auth_input
    case "${socks5_auth_input}" in
        2) SOCKS5_ENABLE_AUTH="no" ;;
        *) SOCKS5_ENABLE_AUTH="yes" ;;
    esac

    if [[ "$SOCKS5_ENABLE_AUTH" == "yes" ]]; then
        echo ""
        echo -e "请输入用户名 ${YELLOW}(回车默认: proxy)${NC}: "
        read -r socks5_user_input
        SOCKS5_USER="${socks5_user_input:-proxy}"
        print_info "用户名: ${SOCKS5_USER}"

        echo ""
        echo -e "请输入密码 ${YELLOW}(回车随机生成)${NC}: "
        read -r socks5_pass_input
        if [[ -z "$socks5_pass_input" ]]; then
            if [[ -z "$SOCKS_PASS" ]]; then
                SOCKS_PASS=$(openssl rand -base64 12 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 24)
                [[ -z "$SOCKS_PASS" ]] && SOCKS_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
            fi
            print_info "密码: ${SOCKS_PASS}"
        else
            SOCKS_PASS="$socks5_pass_input"
            print_info "密码: ${SOCKS_PASS}"
        fi
    else
        SOCKS5_USER=""
        SOCKS_PASS=""
        print_info "无认证模式"
    fi

    echo ""
    echo -e "请输入节点名称: "
    read -r socks5_node_name
    if [[ -z "$socks5_node_name" ]]; then
        socks5_node_name="SOCKS5-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${socks5_node_name}"
    SOCKS5_NODE_NAME="$socks5_node_name"

    if [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_socks5
    else
        sb_setup_socks5
    fi

    generate_socks5_link

    save_keys_to_file

    echo ""
    print_success "SOCKS5 协议配置完成!"
}

sb_setup_socks5() {
    print_info "生成 sing-box SOCKS5 配置..."

    local socks5_tag="socks5-in"

    local sb_config_file="${SB_DIR}/config.json"
    if [[ ! -f "$sb_config_file" ]]; then
        print_error "sing-box 配置文件不存在: ${sb_config_file}"
        return 1
    fi

    local auth_config=""
    if [[ "$SOCKS5_ENABLE_AUTH" == "yes" ]]; then
        auth_config=$(cat <<EOF
"authenticator": {
    "enabled": true,
    "username": "${SOCKS5_USER}",
    "password": "${SOCKS_PASS}"
}
EOF
)
    fi

    local sb_inbound_config
    if [[ -n "$auth_config" ]]; then
        sb_inbound_config=$(cat <<EOF
{
    "type": "socks",
    "tag": "${socks5_tag}",
    "listen": "::",
    "listen_port": ${SOCKS5_PORT},
    ${auth_config}
}
EOF
)
    else
        sb_inbound_config=$(cat <<EOF
{
    "type": "socks",
    "tag": "${socks5_tag}",
    "listen": "::",
    "listen_port": ${SOCKS5_PORT}
}
EOF
)
    fi

    local temp_file=$(mktemp)
    echo "${sb_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${sb_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${sb_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${sb_inbound_config}]" "${sb_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${sb_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${sb_config_file}"
            chmod 644 "${sb_config_file}"
            print_success "sing-box SOCKS5 配置已添加到 ${sb_config_file}"
        else
            print_error "更新 sing-box 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 SOCKS5 inbound 配置"
        echo "${sb_inbound_config}"
    fi

    return 0
}

xray_setup_socks5() {
    print_info "生成 xray SOCKS5 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local auth_config=""
    if [[ "$SOCKS5_ENABLE_AUTH" == "yes" ]]; then
        auth_config=$(cat <<EOF
"accounts": [
    {
        "user": "${SOCKS5_USER}",
        "pass": "${SOCKS_PASS}"
    }
]
EOF
)
    fi

    local xray_inbound_config
    if [[ -n "$auth_config" ]]; then
        xray_inbound_config=$(cat <<EOF
{
    "protocol": "socks",
    "port": ${SOCKS5_PORT},
    "listen": "::",
    "settings": {
        "auth": "password",
        "udp": true,
        ${auth_config}
    },
    "tag": "socks5-in"
}
EOF
)
    else
        xray_inbound_config=$(cat <<EOF
{
    "protocol": "socks",
    "port": ${SOCKS5_PORT},
    "listen": "::",
    "settings": {
        "auth": "noauth",
        "udp": true
    },
    "tag": "socks5-in"
}
EOF
)
    fi

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray SOCKS5 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 SOCKS5 inbound 配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_socks5_link() {
    print_info "生成 SOCKS5 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SOCKS5_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${SOCKS5_NODE_NAME}"

    local socks5_link=""
    if [[ "$SOCKS5_ENABLE_AUTH" == "yes" ]]; then
        socks5_link="socks5://${SOCKS5_USER}:${SOCKS_PASS}@${server_address}:${SOCKS5_PORT}#${encoded_name}"
    else
        socks5_link="socks5://${server_address}:${SOCKS5_PORT}#${encoded_name}"
    fi

    SOCKS5_LINKS="${socks5_link}"

    echo ""
    echo -e "${GREEN}SOCKS5 链接已生成:${NC}"
    echo "${socks5_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

# ==================== HTTP 协议配置 ====================

setup_http() {
    print_info "开始配置 HTTP 协议..."

    load_keys_from_file

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               HTTP 协议配置${CYAN}                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "请选择传输方式:"
    echo -e "  ${GREEN}1${NC}. HTTP (不加密)"
    echo -e "  ${GREEN}2${NC}. HTTPS (TLS 加密，推荐)"
    echo -e "  ${YELLOW}请选择 (回车默认: 2)${NC}: "
    read -r http_tls_input
    case "${http_tls_input}" in
        1) HTTP_TLS_ENABLE="no" ;;
        *) HTTP_TLS_ENABLE="yes" ;;
    esac
    print_info "TLS 加密: ${HTTP_TLS_ENABLE}"

    echo ""
    echo -e "请输入端口 ${YELLOW}(回车随机空闲端口)${NC}: "
    read -r http_port_input
    if [[ -z "$http_port_input" ]]; then
        HTTP_PORT=$(get_random_port)
    else
        HTTP_PORT="$http_port_input"
    fi
    print_info "端口: ${HTTP_PORT}"

    if [[ "$HTTP_TLS_ENABLE" == "yes" ]]; then
        echo ""
        echo -e "请输入 SNI 域名 ${YELLOW}(回车默认: ${DEFAULT_SNI})${NC}: "
        read -r http_sni_input
        HTTP_SNI="${http_sni_input:-${DEFAULT_SNI}}"
        print_info "SNI 域名: ${HTTP_SNI}"

        echo ""
        echo -e "请选择指纹:"
        echo -e "  ${GREEN}1${NC}. chrome (推荐)"
        echo -e "  ${GREEN}2${NC}. firefox"
        echo -e "  ${GREEN}3${NC}. safari"
        echo -e "  ${GREEN}4${NC}. ios"
        echo -e "  ${GREEN}5${NC}. android"
        echo -e "  ${GREEN}6${NC}. random"
        echo -e "  ${YELLOW}请选择 (回车默认: 1)${NC}: "
        read -r http_fp_input
        case "${http_fp_input}" in
            2) HTTP_FP="firefox" ;;
            3) HTTP_FP="safari" ;;
            4) HTTP_FP="ios" ;;
            5) HTTP_FP="android" ;;
            6) HTTP_FP="random" ;;
            *) HTTP_FP="chrome" ;;
        esac
        print_info "指纹: ${HTTP_FP}"
    fi

    echo ""
    echo -e "是否启用用户认证? ${YELLOW}(回车默认: 是)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是 (推荐)"
    echo -e "  ${GREEN}2${NC}. 否"
    read -r http_auth_input
    case "${http_auth_input}" in
        2) HTTP_ENABLE_AUTH="no" ;;
        *) HTTP_ENABLE_AUTH="yes" ;;
    esac

    if [[ "$HTTP_ENABLE_AUTH" == "yes" ]]; then
        echo ""
        echo -e "请输入用户名 ${YELLOW}(回车默认: proxy)${NC}: "
        read -r http_user_input
        HTTP_USER="${http_user_input:-proxy}"
        print_info "用户名: ${HTTP_USER}"

        echo ""
        echo -e "请输入密码 ${YELLOW}(回车随机生成)${NC}: "
        read -r http_pass_input
        if [[ -z "$http_pass_input" ]]; then
            HTTP_PASS=$(openssl rand -base64 12 2>/dev/null | tr -dc 'a-zA-Z0-9' | head -c 24)
            [[ -z "$HTTP_PASS" ]] && HTTP_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 24 | head -n 1)
            print_info "密码: ${HTTP_PASS}"
        else
            HTTP_PASS="$http_pass_input"
            print_info "密码: ${HTTP_PASS}"
        fi
    else
        HTTP_USER=""
        HTTP_PASS=""
        print_info "无认证模式"
    fi

    echo ""
    echo -e "请输入节点名称: "
    read -r http_node_name
    if [[ -z "$http_node_name" ]]; then
        http_node_name="HTTP-$(date +%Y%m%d-%H%M%S)"
    fi
    print_info "节点名称: ${http_node_name}"
    HTTP_NODE_NAME="$http_node_name"

    if [[ "$HTTP_TLS_ENABLE" == "yes" ]]; then
        gen_cert_for_http "${HTTP_SNI}"
    fi

    if [[ "$CORE_TYPE" == "xray" ]]; then
        xray_setup_http
    else
        print_warning "HTTP 协议 xray 支持更好，将使用 xray 配置"
        if [[ -f "${XRAY_DIR}/xray" ]]; then
            xray_setup_http
        else
            print_error "xray 未安装，请先安装 xray 或选择其他核心"
            return 1
        fi
    fi

    generate_http_link

    save_keys_to_file

    echo ""
    print_success "HTTP 协议配置完成!"
}

gen_cert_for_http() {
    local domain="$1"
    local cert_dir="${CONFIG_DIR}/certs"
    local cert_file="${cert_dir}/${domain}.crt"
    local key_file="${cert_dir}/${domain}.key"

    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        print_info "证书已存在: ${domain}"
        return 0
    fi

    mkdir -p "${cert_dir}"

    print_info "为 ${domain} 生成自签名证书..."

    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -subj "/CN=${domain}" \
        2>/dev/null

    if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
        print_error "证书生成失败"
        return 1
    fi

    chmod 600 "$key_file"
    chmod 644 "$cert_file"

    print_success "证书生成完成: ${cert_file}"
    return 0
}

xray_setup_http() {
    print_info "生成 xray HTTP 配置..."

    local xray_config_file="${XRAY_DIR}/config.json"
    if [[ ! -f "$xray_config_file" ]]; then
        print_error "xray 配置文件不存在: ${xray_config_file}"
        return 1
    fi

    local auth_config=""
    if [[ "$HTTP_ENABLE_AUTH" == "yes" ]]; then
        auth_config=$(cat <<EOF
"accounts": [
    {
        "user": "${HTTP_USER}",
        "pass": "${HTTP_PASS}"
    }
]
EOF
)
    fi

    local xray_inbound_config
    if [[ "$HTTP_TLS_ENABLE" == "yes" ]]; then
        local cert_file="${CONFIG_DIR}/certs/${HTTP_SNI}.crt"
        local key_file="${CONFIG_DIR}/certs/${HTTP_SNI}.key"

        if [[ -n "$auth_config" ]]; then
            xray_inbound_config=$(cat <<EOF
{
    "protocol": "http",
    "port": ${HTTP_PORT},
    "listen": "::",
    "settings": {
        "auth": "password",
        "udp": true,
        ${auth_config}
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${HTTP_SNI}",
            "certificate": [
                {
                    "certificateFile": "${cert_file}",
                    "keyFile": "${key_file}"
                }
            ]
        }
    },
    "tag": "http-in"
}
EOF
)
        else
            xray_inbound_config=$(cat <<EOF
{
    "protocol": "http",
    "port": ${HTTP_PORT},
    "listen": "::",
    "settings": {
        "auth": "noauth",
        "udp": true
    },
    "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
            "serverName": "${HTTP_SNI}",
            "certificate": [
                {
                    "certificateFile": "${cert_file}",
                    "keyFile": "${key_file}"
                }
            ]
        }
    },
    "tag": "http-in"
}
EOF
)
        fi
    else
        if [[ -n "$auth_config" ]]; then
            xray_inbound_config=$(cat <<EOF
{
    "protocol": "http",
    "port": ${HTTP_PORT},
    "listen": "::",
    "settings": {
        "auth": "password",
        "udp": true,
        ${auth_config}
    },
    "tag": "http-in"
}
EOF
)
        else
            xray_inbound_config=$(cat <<EOF
{
    "protocol": "http",
    "port": ${HTTP_PORT},
    "listen": "::",
    "settings": {
        "auth": "noauth",
        "udp": true
    },
    "tag": "http-in"
}
EOF
)
        fi
    fi

    local temp_file=$(mktemp)
    echo "${xray_inbound_config}" > "${temp_file}"

    if command -v jq &>/dev/null; then
        local existing_inbounds=$(jq '.inbounds // []' "${xray_config_file}" 2>/dev/null)
        local new_inbounds

        if [[ "$existing_inbounds" == "[]" || -z "$existing_inbounds" ]]; then
            new_inbounds="[${xray_inbound_config}]"
        else
            new_inbounds=$(jq ".inbounds + [${xray_inbound_config}]" "${xray_config_file}" 2>/dev/null)
        fi

        jq ".inbounds = ${new_inbounds}" "${xray_config_file}" > "${temp_file}" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            mv "${temp_file}" "${xray_config_file}"
            chmod 644 "${xray_config_file}"
            print_success "xray HTTP 配置已添加到 ${xray_config_file}"
        else
            print_error "更新 xray 配置失败"
            rm -f "${temp_file}"
            return 1
        fi
    else
        print_warning "jq 未安装，无法合并配置，请手动添加 HTTP inbound 配置"
        echo "${xray_inbound_config}"
    fi

    return 0
}

generate_http_link() {
    print_info "生成 HTTP 链接..."

    local server_address
    server_address="$(get_public_ipv4)"

    if [[ -z "$server_address" ]]; then
        print_error "无法获取服务器 IP 地址"
        return 1
    fi

    local encoded_name
    encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${HTTP_NODE_NAME}'))" 2>/dev/null)
    [[ -z "$encoded_name" ]] && encoded_name="${HTTP_NODE_NAME}"

    local http_link=""
    if [[ "$HTTP_ENABLE_AUTH" == "yes" ]]; then
        if [[ "$HTTP_TLS_ENABLE" == "yes" ]]; then
            http_link="https://${HTTP_USER}:${HTTP_PASS}@${server_address}:${HTTP_PORT}#${encoded_name}"
        else
            http_link="http://${HTTP_USER}:${HTTP_PASS}@${server_address}:${HTTP_PORT}#${encoded_name}"
        fi
    else
        if [[ "$HTTP_TLS_ENABLE" == "yes" ]]; then
            http_link="https://${server_address}:${HTTP_PORT}#${encoded_name}"
        else
            http_link="http://${server_address}:${HTTP_PORT}#${encoded_name}"
        fi
    fi

    HTTPS_LINKS="${http_link}"

    echo ""
    echo -e "${GREEN}HTTP 链接已生成:${NC}"
    echo "${http_link}" | fold -s -w 80 | sed 's/^/  /'
    echo ""
}

get_random_fingerprint() {
    local fingerprints=("chrome" "firefox" "safari" "ios" "android" "random")
    local random_index=$((RANDOM % ${#fingerprints[@]}))
    echo "${fingerprints[$random_index]}"
}

get_public_ipv4() {
    local ipv4=""
    if [[ -f "${IP_CONFIG_FILE}" ]]; then
        ipv4=$(grep -oP 'IPv4=\K[\w.:\[\]]+' "${IP_CONFIG_FILE}" 2>/dev/null | head -1)
    fi

    if [[ -z "$ipv4" ]]; then
        ipv4=$(curl -s -4 --max-time 5 https://api.ipify.org 2>/dev/null)
    fi

    if [[ -z "$ipv4" ]]; then
        ipv4=$(curl -s -4 --max-time 5 https://ifconfig.me 2>/dev/null)
    fi

    if [[ -z "$ipv4" ]]; then
        ipv4=$(curl -s -4 --max-time 5 https://icanhazip.com 2>/dev/null)
    fi

    echo "$ipv4"
}

get_public_ipv6() {
    local ipv6=""
    if [[ -f "${IP_CONFIG_FILE}" ]]; then
        ipv6=$(grep -oP 'IPv6=\K[\w:.[\]]+' "${IP_CONFIG_FILE}" 2>/dev/null | head -1)
    fi

    if [[ -z "$ipv6" ]]; then
        ipv6=$(curl -s -6 --max-time 5 https://api.ipify.org 2>/dev/null)
    fi

    if [[ -z "$ipv6" ]]; then
        ipv6=$(curl -s -6 --max-time 5 https://ifconfig.me 2>/dev/null)
    fi

    echo "$ipv6"
}

# ==================== 证书管理 ====================

gen_cert_for_sni() {
    local sni_domain="$1"
    local cert_dir="${CONFIG_DIR}/certs"
    local cert_file="${cert_dir}/${sni_domain}.crt"
    local key_file="${cert_dir}/${sni_domain}.key"

    if [[ -f "$cert_file" && -f "$key_file" ]]; then
        print_info "证书已存在: ${sni_domain}"
        return 0
    fi

    mkdir -p "${cert_dir}"

    print_info "为 ${sni_domain} 生成自签名证书..."

    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$key_file" \
        -out "$cert_file" \
        -days 365 \
        -subj "/CN=${sni_domain}" \
        2>/dev/null

    if [[ ! -f "$cert_file" || ! -f "$key_file" ]]; then
        print_error "证书生成失败"
        return 1
    fi

    chmod 600 "$key_file"
    chmod 644 "$cert_file"

    print_success "证书生成完成: ${cert_file}"
    return 0
}

# ==================== 链接管理 ====================

ALL_LINKS_TEXT=""

save_links_to_files() {
    mkdir -p "${LINK_DIR}"

    {
        echo "# Proxy Toolkit Links - Generated at $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Core Type: ${CORE_TYPE}"
        echo ""
    } > "${ALL_LINKS_FILE}"

    if [[ -n "$REALITY_LINKS" ]]; then
        {
            echo "# Reality Links"
            echo "${REALITY_LINKS}"
        } > "${REALITY_LINKS_FILE}"
        echo "${REALITY_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$HYSTERIA2_LINKS" ]]; then
        {
            echo "# Hysteria2 Links"
            echo "${HYSTERIA2_LINKS}"
        } > "${HYSTERIA2_LINKS_FILE}"
        echo "${HYSTERIA2_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$SOCKS5_LINKS" ]]; then
        {
            echo "# SOCKS5 Links"
            echo "${SOCKS5_LINKS}"
        } > "${SOCKS5_LINKS_FILE}"
        echo "${SOCKS5_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$SHADOWTLS_LINKS" ]]; then
        {
            echo "# ShadowTLS Links"
            echo "${SHADOWTLS_LINKS}"
        } > "${SHADOWTLS_LINKS_FILE}"
        echo "${SHADOWTLS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$HTTPS_LINKS" ]]; then
        {
            echo "# HTTPS Links"
            echo "${HTTPS_LINKS}"
        } > "${HTTPS_LINKS_FILE}"
        echo "${HTTPS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$ANYTLS_LINKS" ]]; then
        {
            echo "# AnyTLS Links"
            echo "${ANYTLS_LINKS}"
        } > "${ANYTLS_LINKS_FILE}"
        echo "${ANYTLS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$VLESS_LINKS" ]]; then
        {
            echo "# VLESS Links"
            echo "${VLESS_LINKS}"
        } > "${VLESS_LINKS_FILE}"
        echo "${VLESS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$VMESS_LINKS" ]]; then
        {
            echo "# VMess Links"
            echo "${VMESS_LINKS}"
        } > "${VMESS_LINKS_FILE}"
        echo "${VMESS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$TROJAN_LINKS" ]]; then
        {
            echo "# Trojan Links"
            echo "${TROJAN_LINKS}"
        } > "${TROJAN_LINKS_FILE}"
        echo "${TROJAN_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    if [[ -n "$SHADOWSOCKS_LINKS" ]]; then
        {
            echo "# Shadowsocks Links"
            echo "${SHADOWSOCKS_LINKS}"
        } > "${SHADOWSOCKS_LINKS_FILE}"
        echo "${SHADOWSOCKS_LINKS}" >> "${ALL_LINKS_FILE}"
    fi

    chmod 644 "${LINK_DIR}"/*.txt 2>/dev/null

    print_success "链接已保存到 ${LINK_DIR}/"
    echo ""
    echo -e "  ${GREEN}Reality:${NC}     ${REALITY_LINKS_FILE}"
    [[ -n "$HYSTERIA2_LINKS" ]] && echo -e "  ${GREEN}Hysteria2:${NC}  ${HYSTERIA2_LINKS_FILE}"
    [[ -n "$SOCKS5_LINKS" ]] && echo -e "  ${GREEN}SOCKS5:${NC}     ${SOCKS5_LINKS_FILE}"
    [[ -n "$HTTPS_LINKS" ]] && echo -e "  ${GREEN}HTTPS:${NC}      ${HTTPS_LINKS_FILE}"
    [[ -n "$VLESS_LINKS" ]] && echo -e "  ${GREEN}VLESS:${NC}     ${VLESS_LINKS_FILE}"
    [[ -n "$VMESS_LINKS" ]] && echo -e "  ${GREEN}VMess:${NC}     ${VMESS_LINKS_FILE}"
    echo ""
    echo -e "  ${YELLOW}汇总文件:${NC} ${ALL_LINKS_FILE}"
    echo ""
}

load_links_from_files() {
    if [[ ! -d "${LINK_DIR}" ]]; then
        return 1
    fi

    [[ -f "${REALITY_LINKS_FILE}" ]] && REALITY_LINKS=$(grep -v '^#' "${REALITY_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${HYSTERIA2_LINKS_FILE}" ]] && HYSTERIA2_LINKS=$(grep -v '^#' "${HYSTERIA2_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${SOCKS5_LINKS_FILE}" ]] && SOCKS5_LINKS=$(grep -v '^#' "${SOCKS5_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${SHADOWTLS_LINKS_FILE}" ]] && SHADOWTLS_LINKS=$(grep -v '^#' "${SHADOWTLS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${HTTPS_LINKS_FILE}" ]] && HTTPS_LINKS=$(grep -v '^#' "${HTTPS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${ANYTLS_LINKS_FILE}" ]] && ANYTLS_LINKS=$(grep -v '^#' "${ANYTLS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${VLESS_LINKS_FILE}" ]] && VLESS_LINKS=$(grep -v '^#' "${VLESS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${VMESS_LINKS_FILE}" ]] && VMESS_LINKS=$(grep -v '^#' "${VMESS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${TROJAN_LINKS_FILE}" ]] && TROJAN_LINKS=$(grep -v '^#' "${TROJAN_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')
    [[ -f "${SHADOWSOCKS_LINKS_FILE}" ]] && SHADOWSOCKS_LINKS=$(grep -v '^#' "${SHADOWSOCKS_LINKS_FILE}" | grep -v '^[[:space:]]*$' | tr -d '\n')

    return 0
}

cleanup_links() {
    print_warning "即将清理所有链接文件..."
    read -p "确认清理? (y/N): " confirm
    [[ "${confirm}" != "y" && "${confirm}" != "Y" ]] && return 0

    rm -f "${LINK_DIR}"/*.txt 2>/dev/null

    REALITY_LINKS=""
    HYSTERIA2_LINKS=""
    SOCKS5_LINKS=""
    SHADOWTLS_LINKS=""
    HTTPS_LINKS=""
    ANYTLS_LINKS=""
    VLESS_LINKS=""
    VMESS_LINKS=""
    TROJAN_LINKS=""
    SHADOWSOCKS_LINKS=""
    ALL_LINKS_TEXT=""

    print_success "链接文件已清理"
}

add_link() {
    local link="$1"
    local protocol="$2"
    local extra_info="${3:-}"

    [[ -z "$link" ]] && return 1

    case "$protocol" in
        reality|Reality|REALITY)
            [[ -n "$REALITY_LINKS" ]] && REALITY_LINKS+="
"
            REALITY_LINKS+="${link}"
            ;;
        hysteria2|Hysteria2|HYSTERIA2|h2|H2)
            [[ -n "$HYSTERIA2_LINKS" ]] && HYSTERIA2_LINKS+="
"
            HYSTERIA2_LINKS+="${link}"
            ;;
        socks5|SOCKS5|Socks5)
            [[ -n "$SOCKS5_LINKS" ]] && SOCKS5_LINKS+="
"
            SOCKS5_LINKS+="${link}"
            ;;
        shadowtls|ShadowTLS|SHADOWTLS)
            [[ -n "$SHADOWTLS_LINKS" ]] && SHADOWTLS_LINKS+="
"
            SHADOWTLS_LINKS+="${link}"
            ;;
        https|HTTPS|Https)
            [[ -n "$HTTPS_LINKS" ]] && HTTPS_LINKS+="
"
            HTTPS_LINKS+="${link}"
            ;;
        anytls|AnyTLS|ANYTLS)
            [[ -n "$ANYTLS_LINKS" ]] && ANYTLS_LINKS+="
"
            ANYTLS_LINKS+="${link}"
            ;;
        vless|VLESS|Vless)
            [[ -n "$VLESS_LINKS" ]] && VLESS_LINKS+="
"
            VLESS_LINKS+="${link}"
            ;;
        vmess|VMess|VMESS)
            [[ -n "$VMESS_LINKS" ]] && VMESS_LINKS+="
"
            VMESS_LINKS+="${link}"
            ;;
        trojan|Trojan|TROJAN)
            [[ -n "$TROJAN_LINKS" ]] && TROJAN_LINKS+="
"
            TROJAN_LINKS+="${link}"
            ;;
        shadowsocks|Shadowsocks|SHADOWSOCKS|ss|SS)
            [[ -n "$SHADOWSOCKS_LINKS" ]] && SHADOWSOCKS_LINKS+="
"
            SHADOWSOCKS_LINKS+="${link}"
            ;;
        *)
            [[ -n "$ALL_LINKS_TEXT" ]] && ALL_LINKS_TEXT+="
"
            ALL_LINKS_TEXT+="${link}"
            ;;
    esac
}

display_all_links() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ${GREEN}节点链接汇总${CYAN}                   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    local has_links=0

    if [[ -n "$REALITY_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ Reality ───────────────────────────────────────┐${NC}"
        echo "${REALITY_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$HYSTERIA2_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ Hysteria2 ─────────────────────────────────────┐${NC}"
        echo "${HYSTERIA2_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$SOCKS5_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ SOCKS5 ─────────────────────────────────────────┐${NC}"
        echo "${SOCKS5_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$HTTPS_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ HTTPS ──────────────────────────────────────────┐${NC}"
        echo "${HTTPS_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$VLESS_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ VLESS ──────────────────────────────────────────┐${NC}"
        echo "${VLESS_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$VMESS_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ VMess ──────────────────────────────────────────┐${NC}"
        echo "${VMESS_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$TROJAN_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ Trojan ─────────────────────────────────────────┐${NC}"
        echo "${TROJAN_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ -n "$SHADOWSOCKS_LINKS" ]]; then
        has_links=1
        echo -e "${GREEN}┌─ Shadowsocks ───────────────────────────────────┐${NC}"
        echo "${SHADOWSOCKS_LINKS}" | fold -s -w 80 | sed 's/^/  /'
        echo ""
    fi

    if [[ $has_links -eq 0 ]]; then
        echo -e "${YELLOW}暂无链接，请先生成节点配置${NC}"
    fi

    echo ""
}

get_link_by_protocol() {
    local protocol="$1"
    case "$protocol" in
        reality|Reality|REALITY) echo "$REALITY_LINKS" ;;
        hysteria2|Hysteria2|HYSTERIA2|h2|H2) echo "$HYSTERIA2_LINKS" ;;
        socks5|SOCKS5|Socks5) echo "$SOCKS5_LINKS" ;;
        shadowtls|ShadowTLS|SHADOWTLS) echo "$SHADOWTLS_LINKS" ;;
        https|HTTPS|Https) echo "$HTTPS_LINKS" ;;
        anytls|AnyTLS|ANYTLS) echo "$ANYTLS_LINKS" ;;
        vless|VLESS|Vless) echo "$VLESS_LINKS" ;;
        vmess|VMess|VMESS) echo "$VMESS_LINKS" ;;
        trojan|Trojan|TROJAN) echo "$TROJAN_LINKS" ;;
        shadowsocks|Shadowsocks|SHADOWSOCKS|ss|SS) echo "$SHADOWSOCKS_LINKS" ;;
        *) echo "" ;;
    esac
}

# ==================== 中转配置 ====================

load_relay_config() {
    RELAY_TAGS=()
    RELAY_JSONS=()
    RELAY_DESCS=()

    if [[ ! -f "${RELAY_FILE}" ]]; then
        return 0
    fi

    while IFS='|' read -r tag desc json; do
        [[ -z "$tag" ]] && continue
        RELAY_TAGS+=("$tag")
        RELAY_DESCS+=("$desc")
        RELAY_JSONS+=("$json")
    done < "${RELAY_FILE}"
}

save_relay_config() {
    mkdir -p "${CONFIG_DIR}"
    > "${RELAY_FILE}"

    local count=${#RELAY_TAGS[@]}
    for ((i=0; i<count; i++)); do
        echo "${RELAY_TAGS[$i]}|${RELAY_DESCS[$i]}|${RELAY_JSONS[$i]}" >> "${RELAY_FILE}"
    done
}

list_relays() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ${GREEN}中转列表${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    load_relay_config

    local count=${#RELAY_TAGS[@]}
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}暂无中转配置${NC}"
        echo ""
        return 0
    fi

    for ((i=0; i<count; i++)); do
        local tag="${RELAY_TAGS[$i]}"
        local desc="${RELAY_DESCS[$i]}"
        local num=$((i+1))

        echo -e "  ${GREEN}[${num}]${NC} ${CYAN}${tag}${NC}"
        echo -e "      描述: ${desc}"
        echo ""
    done

    return 0
}

add_relay() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ${GREEN}添加中转${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local relay_type
    local relay_address
    local relay_port
    local relay_user
    local relay_pass
    local relay_tag

    echo -e "请选择中转类型:"
    echo -e "  ${GREEN}[1]${NC} SOCKS5"
    echo -e "  ${GREEN}[2]${NC} HTTP"
    echo -e "  ${GREEN}[3]${NC} 返回"
    echo ""
    read -p "请选择 (1-3): " type_input

    case "${type_input}" in
        1) relay_type="socks5" ;;
        2) relay_type="http" ;;
        *) return 0 ;;
    esac

    echo ""
    echo -e "${YELLOW}注意: 中转服务器将接收客户端连接并转发到本服务器${NC}"
    echo ""

    echo -e "请输入中转服务器地址 ${YELLOW}(IP 或域名)${NC}: "
    read -r relay_address
    if [[ -z "$relay_address" ]]; then
        print_error "地址不能为空"
        return 1
    fi

    echo ""
    echo -e "请输入中转服务器端口 ${YELLOW}(1-65535)${NC}: "
    read -r relay_port
    if [[ -z "$relay_port" || ! "$relay_port" =~ ^[0-9]+$ || "$relay_port" -lt 1 || "$relay_port" -gt 65535 ]]; then
        print_error "端口无效"
        return 1
    fi

    echo ""
    echo -e "是否需要认证? ${YELLOW}(回车默认: 否)${NC}: "
    echo -e "  ${GREEN}1${NC}. 是"
    echo -e "  ${GREEN}2${NC}. 否"
    read -r auth_input

    if [[ "${auth_input}" == "1" ]]; then
        echo ""
        echo -e "请输入用户名: "
        read -r relay_user
        echo ""
        echo -e "请输入密码: "
        read -r relay_pass
    fi

    echo ""
    echo -e "请输入中转标签 ${YELLOW}(用于标识此中转，如: relay-01)${NC}: "
    read -r relay_tag
    if [[ -z "$relay_tag" ]]; then
        relay_tag="relay-${#RELAY_TAGS[@]}"
    fi

    local relay_desc="${relay_type}://${relay_address}:${relay_port}"
    if [[ -n "$relay_user" ]]; then
        relay_desc="${relay_type}://${relay_user}:***@${relay_address}:${relay_port}"
    fi

    local relay_json
    if [[ "$relay_type" == "socks5" ]]; then
        if [[ -n "$relay_user" ]]; then
            relay_json=$(cat <<EOF
{"type":"socks5","server":"${relay_address}","server_port":${relay_port},"username":"${relay_user}","password":"${relay_pass}","version":"5"}
EOF
)
        else
            relay_json=$(cat <<EOF
{"type":"socks5","server":"${relay_address}","server_port":${relay_port},"version":"5"}
EOF
)
        fi
    else
        if [[ -n "$relay_user" ]]; then
            relay_json=$(cat <<EOF
{"type":"http","server":"${relay_address}","server_port":${relay_port},"username":"${relay_user}","password":"${relay_pass}"}
EOF
)
        else
            relay_json=$(cat <<EOF
{"type":"http","server":"${relay_address}","server_port":${relay_port}}
EOF
)
        fi
    fi

    RELAY_TAGS+=("$relay_tag")
    RELAY_DESCS+=("$relay_desc")
    RELAY_JSONS+=("$relay_json")

    save_relay_config

    print_success "中转已添加: ${relay_tag}"
    echo ""
    return 0
}

delete_relay() {
    list_relays

    local count=${#RELAY_TAGS[@]}
    if [[ $count -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo -e "请输入要删除的中转编号 ${YELLOW}(1-${count})${NC}: "
    read -r del_num

    if [[ -z "$del_num" || ! "$del_num" =~ ^[0-9]+$ || "$del_num" -lt 1 || "$del_num" -gt $count ]]; then
        print_error "无效的选择"
        return 1
    fi

    local idx=$((del_num-1))
    local removed_tag="${RELAY_TAGS[$idx]}"

    unset 'RELAY_TAGS[$idx]'
    unset 'RELAY_DESCS[$idx]'
    unset 'RELAY_JSONS[$idx]'

    RELAY_TAGS=("${RELAY_TAGS[@]}")
    RELAY_DESCS=("${RELAY_DESCS[@]}")
    RELAY_JSONS=("${RELAY_JSONS[@]}")

    save_relay_config

    print_success "已删除中转: ${removed_tag}"
    return 0
}

setup_relay() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}中转配置${CYAN}                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""

        list_relays

        echo ""
        echo -e "  ${GREEN}[1]${NC} 添加中转"
        echo -e "  ${GREEN}[2]${NC} 删除中转"
        echo -e "  ${GREEN}[0]${NC} 返回"
        echo ""

        read -p "请选择: " relay_choice

        case "${relay_choice}" in
            1) add_relay ;;
            2) delete_relay ;;
            0) break ;;
            *) print_error "无效选择" ;;
        esac
    done

    return 0
}

generate_relay_config() {
    load_relay_config

    local count=${#RELAY_TAGS[@]}
    if [[ $count -eq 0 ]]; then
        return 0
    fi

    local outbounds_json="["
    local first=true

    for ((i=0; i<count; i++)); do
        local tag="${RELAY_TAGS[$i]}"
        local json="${RELAY_JSONS[$i]}"

        if [[ "$first" == "true" ]]; then
            first=false
        else
            outbounds_json+=","
        fi

        outbounds_json+=$(cat <<EOF
{
    "tag": "${tag}",
    "protocol": "socks5",
    "dialer": ${json}
}
EOF
)
    done

    outbounds_json+="]"

    echo "$outbounds_json"
    return 0
}

# ==================== 主菜单 ====================

get_service_status() {
    local status="unknown"
    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        if [[ $ALPINE -eq 1 ]]; then
            if rc-service sing-box status 2>/dev/null | grep -q 'started'; then
                status="running"
            else
                status="stopped"
            fi
        else
            if systemctl is-active --quiet sing-box 2>/dev/null; then
                status="running"
            else
                status="stopped"
            fi
        fi
    else
        if [[ $ALPINE -eq 1 ]]; then
            if rc-service xray status 2>/dev/null | grep -q 'started'; then
                status="running"
            else
                status="stopped"
            fi
        else
            if systemctl is-active --quiet xray 2>/dev/null; then
                status="running"
            else
                status="stopped"
            fi
        fi
    fi
    echo "$status"
}

get_argo_status() {
    local argo_status="未配置"
    if [[ -f "${ARGO_DIR}/tunnel.token" ]] || [[ -f "${ARGO_DIR}/tunnel.json" ]]; then
        if [[ -f "${ARGO_DIR}/argo.pid" ]]; then
            local pid=$(cat "${ARGO_DIR}/argo.pid" 2>/dev/null)
            if [[ -n "$pid" && -d "/proc/$pid" ]]; then
                argo_status="运行中"
            else
                argo_status="已配置(未运行)"
            fi
        else
            argo_status="已配置"
        fi
    fi
    echo "$argo_status"
}

get_node_count() {
    local count=0
    [[ -n "$REALITY_LINKS" ]] && ((count++))
    [[ -n "$HYSTERIA2_LINKS" ]] && ((count++))
    [[ -n "$SOCKS5_LINKS" ]] && ((count++))
    [[ -n "$HTTPS_LINKS" ]] && ((count++))
    [[ -n "$VLESS_LINKS" ]] && ((count++))
    [[ -n "$VMESS_LINKS" ]] && ((count++))
    [[ -n "$TROJAN_LINKS" ]] && ((count++))
    [[ -n "$SHADOWSOCKS_LINKS" ]] && ((count++))
    [[ -n "$SHADOWTLS_LINKS" ]] && ((count++))
    [[ -n "$ANYTLS_LINKS" ]] && ((count++))
    echo "$count"
}

get_relay_count() {
    load_relay_config
    echo "${#RELAY_TAGS[@]}"
}

show_main_menu() {
    clear
    show_banner

    local service_status=$(get_service_status)
    local argo_status=$(get_argo_status)
    local node_count=$(get_node_count)
    local relay_count=$(get_relay_count)

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${GREEN}核心类型:${NC} ${BOLD}${CORE_TYPE}${NC}"
    echo -e "  ${GREEN}服务状态:${NC} ${BOLD}${service_status}${NC}"
    echo -e "  ${GREEN}Argo状态:${NC} ${BOLD}${argo_status}${NC}"
    echo -e "  ${GREEN}节点数量:${NC} ${BOLD}${node_count}${NC}"
    echo -e "  ${GREEN}中转数量:${NC} ${BOLD}${relay_count}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      ${GREEN}主菜单${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} 添加节点"
    echo -e "  ${GREEN}[2]${NC} 中转配置"
    echo -e "  ${GREEN}[3]${NC} 查看节点"
    echo -e "  ${GREEN}[4]${NC} 重新生成链接"
    echo -e "  ${GREEN}[5]${NC} 切换核心"
    echo -e "  ${GREEN}[6]${NC} Argo Tunnel"
    echo -e "  ${GREEN}[7]${NC} 系统工具"
    echo -e "  ${GREEN}[8]${NC} 核心管理"
    echo ""
    echo -e "  ${GREEN}[0]${NC} 退出"
    echo ""
}

# ==================== 协议选择菜单 ====================

show_protocol_menu() {
    # 首先检查核心是否已安装
    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        if [[ ! -f "${SB_DIR}/sing-box" ]]; then
            print_warning "sing-box 核心未安装，正在自动安装..."
            install_singbox
            if [[ $? -ne 0 ]]; then
                print_error "sing-box 安装失败"
                return 1
            fi
        fi
    else
        if [[ ! -f "${XRAY_DIR}/xray" ]]; then
            print_warning "xray 核心未安装，正在自动安装..."
            install_xray
            if [[ $? -ne 0 ]]; then
                print_error "xray 安装失败"
                return 1
            fi
        fi
    fi

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ${GREEN}选择协议${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        echo -e "  ${GREEN}[1]${NC}  Reality"
        echo -e "  ${GREEN}[2]${NC}  Hysteria2"
        echo -e "  ${GREEN}[3]${NC}  VLESS"
        echo -e "  ${GREEN}[4]${NC}  VMess"
        echo -e "  ${GREEN}[5]${NC}  Trojan"
        echo -e "  ${GREEN}[6]${NC}  Shadowsocks"
        echo -e "  ${GREEN}[7]${NC}  ShadowTLS"
        echo -e "  ${GREEN}[8]${NC}  AnyTLS"
        echo -e "  ${GREEN}[9]${NC}  SOCKS5"
        echo -e "  ${GREEN}[10]${NC} HTTP"
    else
        echo -e "  ${GREEN}[1]${NC}  VLESS + Vision + Reality"
        echo -e "  ${GREEN}[2]${NC}  VMess + WebSocket + TLS"
        echo -e "  ${GREEN}[3]${NC}  Trojan + TLS"
        echo -e "  ${GREEN}[4]${NC}  Shadowsocks"
        echo -e "  ${GREEN}[5]${NC}  HTTP"
        echo -e "  ${GREEN}[6]${NC}  SOCKS5"
    fi

    echo ""
    echo -e "  ${GREEN}[0]${NC} 返回"
    echo ""

    read -p "请选择协议 (0-10): " proto_choice
    echo ""

    local func_name=""
    local proto_name=""

    if [[ "$CORE_TYPE" == "sing-box" ]]; then
        case "${proto_choice}" in
            1) func_name="setup_reality" && proto_name="Reality" ;;
            2) func_name="setup_hysteria2" && proto_name="Hysteria2" ;;
            3) func_name="setup_vless" && proto_name="VLESS" ;;
            4) func_name="setup_vmess" && proto_name="VMess" ;;
            5) func_name="setup_trojan" && proto_name="Trojan" ;;
            6) func_name="setup_shadowsocks" && proto_name="Shadowsocks" ;;
            7) func_name="setup_shadowtls" && proto_name="ShadowTLS" ;;
            8) func_name="setup_anytls" && proto_name="AnyTLS" ;;
            9) func_name="setup_socks5" && proto_name="SOCKS5" ;;
            10) func_name="setup_http" && proto_name="HTTP" ;;
            0) return 0 ;;
            *)
                print_error "无效选择"
                return 1
                ;;
        esac
    else
        case "${proto_choice}" in
            1) func_name="setup_vless" && proto_name="VLESS" ;;
            2) func_name="setup_vmess" && proto_name="VMess" ;;
            3) func_name="setup_trojan" && proto_name="Trojan" ;;
            4) func_name="setup_shadowsocks" && proto_name="Shadowsocks" ;;
            5) func_name="setup_http" && proto_name="HTTP" ;;
            6) func_name="setup_socks5" && proto_name="SOCKS5" ;;
            0) return 0 ;;
            *)
                print_error "无效选择"
                return 1
                ;;
        esac
    fi

    if declare -f "$func_name" > /dev/null 2>&1; then
        $func_name
        return $?
    else
        print_error "协议配置函数不存在: $func_name"
        return 1
    fi
}

# ==================== 主循环 ====================

main_menu() {
    load_core_type

    while true; do
        show_main_menu

        echo ""
        read -p "请选择操作 (0-8): " main_choice
        echo ""

        case "${main_choice}" in
            1)
                show_protocol_menu
                ;;
            2)
                setup_relay
                ;;
            3)
                load_all_links
                display_all_links
                echo ""
                read -p "按回车键继续..."
                ;;
            4)
                regenerate_all_links
                ;;
            5)
                switch_core_type
                ;;
            6)
                setup_argo
                ;;
            7)
                show_system_tools
                ;;
            8)
                show_core_management
                ;;
            0)
                echo ""
                echo -e "${GREEN}感谢使用 Proxy Toolkit！${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "无效选择，请输入 0-8"
                ;;
        esac
    done
}

# ==================== 快捷命令 ====================

setup_shortcuts() {
    print_info "设置快捷命令..."

    local bin_dir="/usr/local/bin"
    mkdir -p "${bin_dir}"

    cat > "${bin_dir}/sb" <<'EOF'
#!/bin/bash
SCRIPT_PATH="/workspace/install.sh"
if [[ -f "$SCRIPT_PATH" ]]; then
    bash "$SCRIPT_PATH" "$@"
else
    echo "脚本不存在: $SCRIPT_PATH"
    exit 1
fi
EOF
    chmod +x "${bin_dir}/sb"

    cat > "${bin_dir}/sb-add" <<EOF
#!/bin/bash
SCRIPT_PATH="/workspace/install.sh"
if [[ -f "$SCRIPT_PATH" ]]; then
    bash "$SCRIPT_PATH" --quick-add "\$@"
else
    echo "脚本不存在: $SCRIPT_PATH"
    exit 1
fi
EOF
    chmod +x "${bin_dir}/sb-add"

    cat > "${bin_dir}/sb-status" <<'EOF'
#!/bin/bash
if systemctl is-active --quiet sing-box 2>/dev/null; then
    echo "sing-box: running"
elif systemctl is-active --quiet xray 2>/dev/null; then
    echo "xray: running"
else
    echo "服务状态: stopped"
fi
EOF
    chmod +x "${bin_dir}/sb-status"

    cat > "${bin_dir}/sb-logs" <<'EOF'
#!/bin/bash
if systemctl is-active --quiet sing-box 2>/dev/null; then
    journalctl -u sing-box -n 50 --no-pager
elif systemctl is-active --quiet xray 2>/dev/null; then
    journalctl -u xray -n 50 --no-pager
else
    echo "服务未运行"
fi
EOF
    chmod +x "${bin_dir}/sb-logs"

    print_success "快捷命令已设置:"
    echo "  sb         - 运行主脚本"
    echo "  sb-add     - 快速添加节点"
    echo "  sb-status  - 查看状态"
    echo "  sb-logs    - 查看日志"
}

show_system_tools() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}系统工具${CYAN}                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} 查看服务状态"
        echo -e "  ${GREEN}[2]${NC} 查看日志"
        echo -e "  ${GREEN}[3]${NC} 启动服务"
        echo -e "  ${GREEN}[4]${NC} 停止服务"
        echo -e "  ${GREEN}[5]${NC} 重启服务"
        echo -e "  ${GREEN}[6]${NC} 设置快捷命令"
        echo -e "  ${GREEN}[7]${NC} 重新获取 IP"
        echo -e "  ${GREEN}[0]${NC} 返回"
        echo ""

        read -p "请选择: " tool_choice

        case "${tool_choice}" in
            1)
                if [[ "$CORE_TYPE" == "sing-box" ]]; then
                    if [[ $ALPINE -eq 1 ]]; then
                        rc-service sing-box status
                    else
                        systemctl status sing-box --no-pager
                    fi
                else
                    if [[ $ALPINE -eq 1 ]]; then
                        rc-service xray status
                    else
                        systemctl status xray --no-pager
                    fi
                fi
                ;;
            2)
                if [[ "$CORE_TYPE" == "sing-box" ]]; then
                    if [[ -f "/var/log/sing-box.log" ]]; then
                        tail -n 50 "/var/log/sing-box.log"
                    else
                        journalctl -u sing-box -n 50 --no-pager
                    fi
                else
                    if [[ -f "/var/log/xray.log" ]]; then
                        tail -n 50 "/var/log/xray.log"
                    else
                        journalctl -u xray -n 50 --no-pager
                    fi
                fi
                ;;
            3)
                svc_start
                print_success "服务已启动"
                ;;
            4)
                svc_stop
                print_success "服务已停止"
                ;;
            5)
                svc_restart
                print_success "服务已重启"
                ;;
            6)
                setup_shortcuts
                ;;
            7)
                get_ip
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

show_core_management() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}核心管理${CYAN}                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} 切换核心类型"
        echo -e "  ${GREEN}[2]${NC} 升级核心"
        echo -e "  ${GREEN}[3]${NC} 卸载核心"
        echo -e "  ${GREEN}[0]${NC} 返回"
        echo ""

        read -p "请选择: " core_choice

        case "${core_choice}" in
            1)
                switch_core_type
                ;;
            2)
                install_core
                ;;
            3)
                echo ""
                echo -e "${RED}警告: 此操作将卸载核心和所有配置！${NC}"
                read -p "确定要继续吗? (yes/no): " confirm
                if [[ "$confirm" == "yes" ]]; then
                    svc_stop
                    svc_disable
                    rm -rf "${INSTALL_DIR}"
                    print_success "核心已卸载"
                fi
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

switch_core_type() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ${GREEN}切换核心${CYAN}                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}当前核心:${NC} ${BOLD}${CORE_TYPE}${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} sing-box"
    echo -e "  ${GREEN}[2]${NC} xray"
    echo -e "  ${GREEN}[0]${NC} 返回"
    echo ""

    read -p "请选择: " choice
    case "${choice}" in
        1)
            CORE_TYPE="sing-box"
            echo "$CORE_TYPE" > "${CONFIG_DIR}/core_type.conf"
            print_success "已切换到 sing-box"
            ;;
        2)
            CORE_TYPE="xray"
            echo "$CORE_TYPE" > "${CONFIG_DIR}/core_type.conf"
            print_success "已切换到 xray"
            ;;
        0)
            return 0
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# ==================== Argo Tunnel 模块 ====================

ARGO_OS=""
ARGO_CORE_TYPE=""
ARGO_PROTOCOL=""
ARGO_IPS=""
ARGO_ISP=""

argo_detect_os() {
    ARGO_OS=$(grep -i PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '"' -f2 | awk '{print $1}' || echo "unknown")
    print_info "Argo 检测系统: ${ARGO_OS}"
}

argo_install_if_missing() {
    local cmd=$1 pkg=$2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        case "$ARGO_OS" in
            Debian|Ubuntu)
                apt update && apt -y install "$pkg" 2>/dev/null
                ;;
            Alpine)
                apk update && apk add -f "$pkg" 2>/dev/null
                ;;
            CentOS|Fedora)
                yum -y update && yum -y install "$pkg" 2>/dev/null
                ;;
            *)
                apt update && apt -y install "$pkg" 2>/dev/null
                ;;
        esac
    fi
}

argo_cleanup_process() {
    local proc_name=$1
    if [[ "$ARGO_OS" == "Alpine" ]]; then
        kill -9 $(ps -ef | grep "$proc_name" | grep -v grep | awk '{print $1}') 2>/dev/null
    else
        kill -9 $(ps -ef | grep "$proc_name" | grep -v grep | awk '{print $2}') 2>/dev/null
    fi
}

argo_is_alpine() {
    [[ "$ARGO_OS" == "Alpine" ]]
}

argo_download_core() {
    local download_dir="${1:-.}"
    mkdir -p "$download_dir"

    local arch=$(uname -m)
    local arch_suffix

    if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
        local core_path="$download_dir/xray"
        if [[ -f "$core_path" ]]; then
            print_info "xray 已存在，跳过下载"
            return
        fi

        local latest_tag=$(curl -sL https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name"' | tr ',' '\n' | grep '"tag_name"' | sed 's/.*: "\(.*\)".*/\1/')
        if [[ -z "$latest_tag" ]]; then
            print_error "无法获取 xray 最新版本，请检查网络"
            exit 1
        fi

        case "$arch" in
            x86_64|amd64)    arch_suffix="64" ;;
            i386|i686)       arch_suffix="32" ;;
            armv8|arm64|aarch64) arch_suffix="arm64-v8a" ;;
            armv7l)          arch_suffix="arm32-v7a" ;;
            *)               print_error "架构 $arch 不支持 xray"; exit 1 ;;
        esac

        local filename="Xray-linux-${arch_suffix}.zip"
        local url="https://github.com/XTLS/Xray-core/releases/download/${latest_tag}/${filename}"
        curl -sL "$url" -o "$download_dir/xray.zip"
        unzip -d "$download_dir/xray_tmp" "$download_dir/xray.zip"
        mv "$download_dir/xray_tmp/xray" "$core_path"
        rm -rf "$download_dir/xray.zip" "$download_dir/xray_tmp"
        chmod +x "$core_path"
        print_success "xray 下载完成"
    else
        local core_path="$download_dir/sing-box"
        if [[ -f "$core_path" ]]; then
            print_info "sing-box 已存在，跳过下载"
            return
        fi

        local latest_tag=$(curl -sL https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep '"tag_name"' | tr ',' '\n' | grep '"tag_name"' | sed 's/.*: "\(.*\)".*/\1/')
        if [[ -z "$latest_tag" ]]; then
            print_error "无法获取 sing-box 最新版本，请检查网络"
            exit 1
        fi

        local version=${latest_tag#v}
        case "$arch" in
            x86_64|amd64)    arch_suffix="amd64" ;;
            aarch64|arm64)   arch_suffix="arm64" ;;
            armv7l)          arch_suffix="armv7" ;;
            *)               print_error "架构 $arch 不支持 sing-box"; exit 1 ;;
        esac

        local filename="sing-box-${version}-linux-${arch_suffix}.tar.gz"
        local url="https://github.com/SagerNet/sing-box/releases/download/${latest_tag}/${filename}"
        curl -sL "$url" -o "$download_dir/sing-box.tar.gz"
        tar -xzf "$download_dir/sing-box.tar.gz" -C "$download_dir"
        mv "$download_dir/sing-box-"*/sing-box "$core_path" 2>/dev/null || mv "$download_dir/sing-box" "$core_path"
        rm -rf "$download_dir/sing-box.tar.gz" "$download_dir"/sing-box-*
        chmod +x "$core_path"
        print_success "sing-box 下载完成"
    fi
}

argo_download_cloudflared() {
    local download_dir="${1:-.}"
    mkdir -p "$download_dir"

    if [[ -f "$download_dir/cloudflared-linux" ]]; then
        print_info "cloudflared 已存在，跳过下载"
        return
    fi

    local arch=$(uname -m)
    local url=""

    case "$arch" in
        x86_64|amd64)   url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
        i386|i686)      url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" ;;
        arm64|aarch64)  url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
        armv7l)         url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" ;;
        *)              print_error "架构 $arch 无 cloudflared 支持"; exit 1 ;;
    esac

    curl -sL "$url" -o "$download_dir/cloudflared-linux"
    chmod +x "$download_dir/cloudflared-linux"
    print_success "cloudflared 下载完成"
}

argo_gen_vmess_link() {
    local argo_host=$1 uuid=$2 urlpath=$3 isp=$4
    local node_name="${isp//_/ }"
    local tls_json="{\"add\":\"www.visa.com.sg\",\"aid\":\"0\",\"host\":\"$argo_host\",\"id\":\"$uuid\",\"net\":\"ws\",\"path\":\"$urlpath\",\"port\":\"443\",\"ps\":\"${node_name}_tls\",\"tls\":\"tls\",\"type\":\"none\",\"v\":\"2\"}"
    local notls_json="{\"add\":\"www.visa.com.sg\",\"aid\":\"0\",\"host\":\"$argo_host\",\"id\":\"$uuid\",\"net\":\"ws\",\"path\":\"$urlpath\",\"port\":\"80\",\"ps\":\"${node_name}\",\"tls\":\"\",\"type\":\"none\",\"v\":\"2\"}"

    if argo_is_alpine; then
        echo "vmess://$(printf "%s" "$tls_json" | base64 | tr -d '\n' | awk '{ORS=(NR%76==0?RS:"");}1')"
        echo "vmess://$(printf "%s" "$notls_json" | base64 | tr -d '\n' | awk '{ORS=(NR%76==0?RS:"");}1')"
    else
        echo "vmess://$(printf "%s" "$tls_json" | base64 -w 0)"
        echo "vmess://$(printf "%s" "$notls_json" | base64 -w 0)"
    fi
}

argo_gen_config() {
    local port=$1 uuid=$2 urlpath=$3 config_file=$4

    if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
        if [[ "$ARGO_PROTOCOL" == "1" ]]; then
            cat > "$config_file" <<EOF
{
    "inbounds": [{
        "port": $port,
        "listen": "localhost",
        "protocol": "vmess",
        "settings": {
            "clients": [{ "id": "$uuid", "alterId": 0 }]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": { "path": "$urlpath" }
        }
    }],
    "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
EOF
        else
            cat > "$config_file" <<EOF
{
    "inbounds": [{
        "port": $port,
        "listen": "localhost",
        "protocol": "vless",
        "settings": {
            "decryption": "none",
            "clients": [{ "id": "$uuid" }]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": { "path": "$urlpath" }
        }
    }],
    "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
EOF
        fi
    else
        if [[ "$ARGO_PROTOCOL" == "1" ]]; then
            cat > "$config_file" <<EOF
{
    "inbounds": [{
        "type": "vmess",
        "tag": "vmess-in",
        "listen": "127.0.0.1",
        "listen_port": $port,
        "users": [{ "uuid": "$uuid", "alterId": 0 }],
        "transport": {
            "type": "ws",
            "path": "$urlpath"
        }
    }],
    "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF
        else
            cat > "$config_file" <<EOF
{
    "inbounds": [{
        "type": "vless",
        "tag": "vless-in",
        "listen": "127.0.0.1",
        "listen_port": $port,
        "users": [{ "uuid": "$uuid" }],
        "transport": {
            "type": "ws",
            "path": "$urlpath"
        }
    }],
    "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF
        fi
    fi
}

argo_start_core() {
    local config_file=$1
    if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
        ./xray run -config "$config_file" >/dev/null 2>&1 &
    else
        ./sing-box run -c "$config_file" >/dev/null 2>&1 &
    fi
}

argo_quicktunnel() {
    clear
    print_info "开始 Argo 梭哈模式..."

    argo_cleanup_process xray
    argo_cleanup_process sing-box
    argo_cleanup_process cloudflared-linux
    rm -rf xray cloudflared-linux xray.zip sing-box sing-box.tar.gz v2ray.txt /tmp/sing-box 2>/dev/null

    argo_download_core "./"
    argo_download_cloudflared "./"

    local arch=$(uname -m)
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local urlpath=$(echo "$uuid" | awk -F- '{print $1}')
    local port=$((RANDOM+10000))

    local config_file="argo_config.json"
    argo_gen_config "$port" "$uuid" "$urlpath" "$config_file"

    if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
        ./xray run -config "$config_file" >/dev/null 2>&1 &
    else
        ./sing-box run -c "$config_file" >/dev/null 2>&1 &
    fi

    ./cloudflared-linux tunnel --url "http://localhost:$port" --no-autoupdate --edge-ip-version "$ARGO_IPS" --protocol http2 > argo.log 2>&1 &
    sleep 1

    local n=0
    local argo_host=""
    while true; do
        n=$((n+1))
        clear
        echo -e "${YELLOW}等待 cloudflare argo 生成地址 已等待 $n 秒${NC}"
        argo_host=$(cat argo.log | grep trycloudflare.com | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')

        if [[ $n -ge 15 ]]; then
            n=0
            argo_cleanup_process cloudflared-linux
            rm -f argo.log
            clear
            print_warning "argo 获取超时，重试中"
            ./cloudflared-linux tunnel --url "http://localhost:$port" --no-autoupdate --edge-ip-version "$ARGO_IPS" --protocol http2 > argo.log 2>&1 &
            sleep 1
        elif [[ -z "$argo_host" ]]; then
            sleep 1
        else
            rm -f argo.log
            break
        fi
    done

    clear
    > v2ray.txt
    local isp_escaped=$(echo "$ARGO_ISP" | sed 's/_/%20/g; s/,/%2C/g')

    if [[ "$ARGO_PROTOCOL" == "1" ]]; then
        echo -e "vmess 链接已生成, 可替换为CF优选IP\n" >> v2ray.txt
        argo_gen_vmess_link "$argo_host" "$uuid" "$urlpath" "$ARGO_ISP" >> v2ray.txt
        echo -e "\n端口 443 可改为 2053 2083 2087 2096 8443\n" >> v2ray.txt
        echo -e "端口 80 可改为 8080 8880 2052 2082 2086 2095" >> v2ray.txt
    else
        echo -e "vless 链接已生成, 可替换为CF优选IP\n" > v2ray.txt
        echo "vless://$uuid@www.visa.com.sg:443?encryption=none&security=tls&type=ws&host=$argo_host&path=$urlpath#${isp_escaped}_tls" >> v2ray.txt
        echo -e "\n端口 443 可改为 2053 2083 2087 2096 8443\n" >> v2ray.txt
        echo "vless://$uuid@www.visa.com.sg:80?encryption=none&security=none&type=ws&host=$argo_host&path=$urlpath#${isp_escaped}" >> v2ray.txt
        echo -e "\n端口 80 可改为 8080 8880 2052 2082 2086 2095" >> v2ray.txt
    fi

    echo ""
    cat v2ray.txt
    echo ""
    echo -e "${GREEN}信息已保存 /root/v2ray.txt，重启失效！${NC}"
    echo ""
    read -p "按回车键继续..."
}

argo_install_service() {
    clear
    print_info "开始 Argo 安装服务模式..."

    mkdir -p "${ARGO_DIR}"
    argo_download_core "${ARGO_DIR}"
    argo_download_cloudflared "${ARGO_DIR}"

    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local urlpath=$(echo "$uuid" | awk -F- '{print $1}')
    local port=$((RANDOM+10000))

    local config_file="${ARGO_DIR}/config.json"
    argo_gen_config "$port" "$uuid" "$urlpath" "$config_file"

    echo "$ARGO_CORE_TYPE" > "${ARGO_DIR}/core_type"

    clear
    echo ""
    echo -e "${RED}请用浏览器打开以下链接授权 CF 域名：如 example.com${NC}"
    echo ""
    "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel login
    clear

    "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel list > argo.log 2>&1
    echo -e "已绑定隧道列表：\n"
    sed 1,2d argo.log | awk '{print $2}'
    echo ""
    read -p "输入要使用的完整二级域名 (如 xxx.example.com): " domain

    if [[ -z "$domain" ]] || [[ $(grep -o '\.' <<< "$domain" | wc -l) -eq 0 ]]; then
        print_error "域名格式错误"
        return 1
    fi

    local name=$(echo "$domain" | awk -F\. '{print $1}')

    if sed 1,2d argo.log | grep -qw "$name"; then
        print_info "隧道 $name 已存在，尝试复用"
        local existing_id=$(sed 1,2d argo.log | awk -v n="$name" '$2==n {print $1}')
        if [[ -f "/root/.cloudflared/${existing_id}.json" ]]; then
            "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel cleanup "$name" >argo.log 2>&1
        else
            "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel delete "$name" >argo.log 2>&1
            "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel create "$name" >argo.log 2>&1
        fi
    else
        "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel create "$name" >argo.log 2>&1
    fi

    "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel list > argo.log 2>&1
    local tunneliud=$(sed 1,2d argo.log | awk -v n="$name" '$2==n {print $1}')
    if [[ -z "$tunneliud" ]]; then
        print_error "无法获取隧道 UUID"
        return 1
    fi

    print_info "绑定域名 $domain"
    "${ARGO_DIR}/cloudflared-linux" --edge-ip-version "$ARGO_IPS" --protocol http2 tunnel route dns --overwrite-dns "$name" "$domain" >argo.log 2>&1

    > "${ARGO_DIR}/v2ray.txt"
    local isp_escaped=$(echo "$ARGO_ISP" | sed 's/_/%20/g; s/,/%2C/g')

    if [[ "$ARGO_PROTOCOL" == "1" ]]; then
        echo -e "vmess 链接已生成\n" >> "${ARGO_DIR}/v2ray.txt"
        argo_gen_vmess_link "$domain" "$uuid" "$urlpath" "$ARGO_ISP" >> "${ARGO_DIR}/v2ray.txt"
        echo -e "\n端口 443 可改为 2053 2083 2087 2096 8443\n端口 80 可改为 8080 8880 2052 2082 2086 2095" >> "${ARGO_DIR}/v2ray.txt"
    else
        echo -e "vless 链接已生成\n" > "${ARGO_DIR}/v2ray.txt"
        echo "vless://$uuid@www.visa.com.sg:443?encryption=none&security=tls&type=ws&host=$domain&path=$urlpath#${isp_escaped}_tls" >> "${ARGO_DIR}/v2ray.txt"
        echo -e "\n端口 443 可改为 2053 2083 2087 2096 8443\n" >> "${ARGO_DIR}/v2ray.txt"
        echo "vless://$uuid@www.visa.com.sg:80?encryption=none&security=none&type=ws&host=$domain&path=$urlpath#${isp_escaped}" >> "${ARGO_DIR}/v2ray.txt"
        echo -e "\n端口 80 可改为 8080 8880 2052 2082 2086 2095" >> "${ARGO_DIR}/v2ray.txt"
    fi

    cat > "${ARGO_DIR}/config.yaml" <<EOF
tunnel: $tunneliud
credentials-file: /root/.cloudflared/${tunneliud}.json

ingress:
  - hostname: '*'
    service: http://localhost:$port
EOF

    if argo_is_alpine; then
        rc-update add cgroups default >/dev/null 2>&1
        rc-service cgroups start >/dev/null 2>&1

        cat > /etc/init.d/argo-cloudflared <<'EOF'
#!/sbin/openrc-run
name="argo-cloudflared"
description="Cloudflare Tunnel for argo"

command="/opt/argo/cloudflared-linux"
command_args="--edge-ip-version $ARGO_IPS --protocol http2 tunnel --config /opt/argo/config.yaml run $name"
pidfile="/run/${name}.pid"
required_files="/opt/argo/config.yaml"
command_background=true

supervisor="supervise-daemon"
respawn_delay=10
respawn_max=0

depend() {
    need net
    after firewall
}
EOF
        chmod +x /etc/init.d/argo-cloudflared

        local core_cmd_args
        if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
            core_cmd_args="run -config /opt/argo/config.json"
        else
            core_cmd_args="run -c /opt/argo/config.json"
        fi

        cat > /etc/init.d/argo-core <<EOF
#!/sbin/openrc-run
name="argo-core"
description="${ARGO_CORE_TYPE} core for argo"

command="/opt/argo/$ARGO_CORE_TYPE"
command_args="$core_cmd_args"
pidfile="/run/\${name}.pid"
required_files="/opt/argo/config.json"
command_background=true

supervisor="supervise-daemon"
respawn_delay=10
respawn_max=0

depend() {
    need net
    after firewall
}
EOF
        chmod +x /etc/init.d/argo-core

        rc-update add argo-cloudflared default
        rc-update add argo-core default
        rc-service argo-cloudflared start >/dev/null 2>&1
        rc-service argo-core start >/dev/null 2>&1

        rm -f /etc/local.d/argo-cloudflared.start /etc/local.d/argo-core.start 2>/dev/null
    else
        cat > /etc/systemd/system/argo-cloudflared.service <<EOF
[Unit]
Description=Cloudflare Tunnel (argo)
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=/opt/argo/cloudflared-linux --edge-ip-version $ARGO_IPS --protocol http2 tunnel --config /opt/argo/config.yaml run $name
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

        local core_exec
        if [[ "$ARGO_CORE_TYPE" == "xray" ]]; then
            core_exec="/opt/argo/xray run -config /opt/argo/config.json"
        else
            core_exec="/opt/argo/sing-box run -c /opt/argo/config.json"
        fi

        cat > /etc/systemd/system/argo-core.service <<EOF
[Unit]
Description=Core Service (argo)
After=network.target

[Service]
TimeoutStartSec=0
Type=simple
ExecStart=$core_exec
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable argo-cloudflared.service argo-core.service
        systemctl start argo-cloudflared.service argo-core.service
    fi

    cat > "${ARGO_DIR}/argo-manager.sh" <<'MANAGER'
#!/bin/bash
CT=$(cat /opt/argo/core_type 2>/dev/null || echo "xray")
clear
while true; do
    if [ -f /etc/alpine-release ]; then
        cstat=$(rc-service argo-cloudflared status 2>/dev/null | grep -q "started" && echo "running" || echo "stop")
        xstat=$(rc-service argo-core status 2>/dev/null | grep -q "started" && echo "running" || echo "stop")
    else
        cstat=$(systemctl is-active argo-cloudflared.service)
        xstat=$(systemctl is-active argo-core.service)
    fi
    echo "cloudflared: $cstat   core($CT): $xstat"
    echo "1. 管理 TUNNEL"
    echo "2. 启动服务"
    echo "3. 停止服务"
    echo "4. 重启服务"
    echo "5. 卸载服务"
    echo "6. 查看 v2ray 链接"
    echo "0. 退出"
    read -p "选择: " menu
    menu=${menu:-0}
    case $menu in
        1)
            clear
            while true; do
                echo "ARGO TUNNEL 列表："
                /opt/argo/cloudflared-linux tunnel list 2>/dev/null | tail -n +3
                echo ""
                echo "1. 删除隧道  0. 返回"
                read -p "选择: " ta
                if [ "$ta" = "1" ]; then
                    read -p "隧道名: " tn
                    /opt/argo/cloudflared-linux tunnel cleanup "$tn" >/dev/null 2>&1
                    /opt/argo/cloudflared-linux tunnel delete "$tn" >/dev/null 2>&1
                    echo "已删除隧道 $tn"
                    sleep 1
                else
                    break
                fi
            done
            ;;
        2)
            if [ -f /etc/alpine-release ]; then
                rc-service argo-cloudflared start >/dev/null 2>&1
                rc-service argo-core start >/dev/null 2>&1
            else
                systemctl start argo-cloudflared.service argo-core.service
            fi
            clear
            ;;
        3)
            if [ -f /etc/alpine-release ]; then
                rc-service argo-cloudflared stop >/dev/null 2>&1
                rc-service argo-core stop >/dev/null 2>&1
            else
                systemctl stop argo-cloudflared.service argo-core.service
            fi
            clear
            ;;
        4)
            if [ -f /etc/alpine-release ]; then
                rc-service argo-cloudflared restart >/dev/null 2>&1
                rc-service argo-core restart >/dev/null 2>&1
            else
                systemctl restart argo-cloudflared.service argo-core.service
            fi
            clear
            ;;
        5)
            if [ -f /etc/alpine-release ]; then
                rc-service argo-cloudflared stop >/dev/null 2>&1
                rc-service argo-core stop >/dev/null 2>&1
                rc-update del argo-cloudflared default
                rc-update del argo-core default
                rm -f /etc/init.d/argo-cloudflared /etc/init.d/argo-core
            else
                systemctl stop argo-cloudflared.service argo-core.service
                systemctl disable argo-cloudflared.service argo-core.service
                rm -f /etc/systemd/system/argo-cloudflared.service /etc/systemd/system/argo-core.service
                systemctl daemon-reload
            fi
            rm -rf /opt/argo /usr/bin/argo ~/.cloudflared
            echo "卸载完成，API Token 请手动删除"
            exit 0
            ;;
        6)
            clear
            cat /opt/argo/v2ray.txt
            ;;
        0)
            echo "退出"
            exit 0
            ;;
    esac
done
MANAGER

    chmod +x "${ARGO_DIR}/argo-manager.sh"
    ln -sf "${ARGO_DIR}/argo-manager.sh" /usr/bin/argo

    clear
    cat "${ARGO_DIR}/v2ray.txt"
    echo ""
    print_success "安装完成！管理命令: argo"
    echo ""
    read -p "按回车键继续..."
}

argo_service_menu() {
    while true; do
        clear
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                 ${GREEN}Argo 服务管理${CYAN}                       ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""

        local cstat="stop"
        local xstat="stop"

        if argo_is_alpine; then
            rc-service argo-cloudflared status 2>/dev/null | grep -q "started" && cstat="running"
            rc-service argo-core status 2>/dev/null | grep -q "started" && xstat="running"
        else
            cstat=$(systemctl is-active argo-cloudflared.service 2>/dev/null || echo "stop")
            xstat=$(systemctl is-active argo-core.service 2>/dev/null || echo "stop")
        fi

        echo -e "  ${GREEN}cloudflared:${NC} ${cstat}"
        echo -e "  ${GREEN}core(${ARGO_CORE_TYPE}):${NC} ${xstat}"
        echo ""

        echo -e "  ${GREEN}[1]${NC} 管理 TUNNEL"
        echo -e "  ${GREEN}[2]${NC} 启动服务"
        echo -e "  ${GREEN}[3]${NC} 停止服务"
        echo -e "  ${GREEN}[4]${NC} 重启服务"
        echo -e "  ${GREEN}[5]${NC} 卸载服务"
        echo -e "  ${GREEN}[6]${NC} 查看 v2ray 链接"
        echo -e "  ${GREEN}[0]${NC} 返回"
        echo ""

        read -p "请选择: " argo_choice

        case "${argo_choice}" in
            1)
                clear
                echo "ARGO TUNNEL 列表："
                "${ARGO_DIR}/cloudflared-linux" tunnel list 2>/dev/null | tail -n +3
                echo ""
                echo "1. 删除隧道  0. 返回"
                read -p "选择: " ta
                if [[ "$ta" == "1" ]]; then
                    read -p "隧道名: " tn
                    "${ARGO_DIR}/cloudflared-linux" tunnel cleanup "$tn" >/dev/null 2>&1
                    "${ARGO_DIR}/cloudflared-linux" tunnel delete "$tn" >/dev/null 2>&1
                    print_success "已删除隧道 $tn"
                    sleep 1
                fi
                ;;
            2)
                if argo_is_alpine; then
                    rc-service argo-cloudflared start >/dev/null 2>&1
                    rc-service argo-core start >/dev/null 2>&1
                else
                    systemctl start argo-cloudflared.service argo-core.service
                fi
                print_success "服务已启动"
                ;;
            3)
                if argo_is_alpine; then
                    rc-service argo-cloudflared stop >/dev/null 2>&1
                    rc-service argo-core stop >/dev/null 2>&1
                else
                    systemctl stop argo-cloudflared.service argo-core.service
                fi
                print_success "服务已停止"
                ;;
            4)
                if argo_is_alpine; then
                    rc-service argo-cloudflared restart >/dev/null 2>&1
                    rc-service argo-core restart >/dev/null 2>&1
                else
                    systemctl restart argo-cloudflared.service argo-core.service
                fi
                print_success "服务已重启"
                ;;
            5)
                argo_uninstall
                return 0
                ;;
            6)
                clear
                if [[ -f "${ARGO_DIR}/v2ray.txt" ]]; then
                    cat "${ARGO_DIR}/v2ray.txt"
                else
                    print_warning "链接文件不存在"
                fi
                ;;
            0)
                return 0
                ;;
            *)
                print_error "无效选择"
                ;;
        esac

        echo ""
        read -p "按回车键继续..."
    done
}

argo_uninstall() {
    echo ""
    read -p "确定要卸载 Argo Tunnel 吗？(y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_info "取消卸载"
        return 0
    fi

    if argo_is_alpine; then
        rc-service argo-cloudflared stop >/dev/null 2>&1
        rc-service argo-core stop >/dev/null 2>&1
        rc-update del argo-cloudflared default 2>/dev/null
        rc-update del argo-core default 2>/dev/null
        rm -f /etc/init.d/argo-cloudflared /etc/init.d/argo-core
        rm -f /etc/local.d/argo-cloudflared.start /etc/local.d/argo-core.start 2>/dev/null
    else
        systemctl stop argo-cloudflared.service argo-core.service 2>/dev/null
        systemctl disable argo-cloudflared.service argo-core.service 2>/dev/null
        rm -f /etc/systemd/system/argo-cloudflared.service /etc/systemd/system/argo-core.service
        systemctl daemon-reload
    fi

    rm -rf "${ARGO_DIR}" /usr/bin/argo ~/.cloudflared

    print_success "卸载完成，API Token 请手动删除"
    echo ""
    read -p "按回车键继续..."
}

argo_menu() {
    argo_detect_os

    while true; do
        clear
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}Argo Tunnel${CYAN}                       ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}核心类型:${NC} ${BOLD}${ARGO_CORE_TYPE}${NC}"
        echo -e "  ${GREEN}协议:${NC} ${BOLD}$([[ "$ARGO_PROTOCOL" == "1" ]] && echo "VMess" || echo "VLESS")${NC}"
        echo -e "  ${GREEN}IP版本:${NC} ${BOLD}$([[ "$ARGO_IPS" == "4" ]] && echo "IPv4" || echo "IPv6")${NC}"
        echo ""

        local argo_installed=0
        [[ -f "${ARGO_DIR}/core_type" ]] && argo_installed=1

        echo -e "  ${GREEN}[1]${NC} 梭哈模式"
        echo -e "  ${GREEN}[2]${NC} 安装服务"
        if [[ $argo_installed -eq 1 ]]; then
            echo -e "  ${GREEN}[3]${NC} 卸载服务"
            echo -e "  ${GREEN}[4]${NC} 管理服务"
        fi
        echo -e "  ${GREEN}[5]${NC} 清空缓存"
        echo -e "  ${GREEN}[0]${NC} 返回"
        echo ""

        read -p "请选择 (0-5): " argo_mode

        case "${argo_mode}" in
            1)
                argo_quicktunnel
                ;;
            2)
                if [[ $argo_installed -eq 1 ]]; then
                    print_warning "服务已安装，跳转管理..."
                    argo_service_menu
                else
                    argo_install_service
                fi
                ;;
            3)
                if [[ $argo_installed -eq 1 ]]; then
                    argo_uninstall
                else
                    print_error "服务未安装"
                fi
                ;;
            4)
                if [[ $argo_installed -eq 1 ]]; then
                    argo_service_menu
                else
                    print_error "服务未安装"
                fi
                ;;
            5)
                argo_cleanup_process xray
                argo_cleanup_process sing-box
                argo_cleanup_process cloudflared-linux
                rm -rf xray cloudflared-linux v2ray.txt sing-box sing-box.tar.gz argo.log 2>/dev/null
                print_success "缓存已清空"
                ;;
            0)
                return 0
                ;;
            *)
                print_error "无效选择"
                ;;
        esac
    done
}

setup_argo() {
    echo ""
    echo -e "${CYAN}请先选择 Argo 配置：${NC}"
    echo ""

    echo -e "选择核心类型:"
    echo -e "  ${GREEN}[1]${NC} xray"
    echo -e "  ${GREEN}[2]${NC} sing-box"
    echo ""
    read -p "请选择 (1-2, 默认1): " argo_core_choice
    argo_core_choice=${argo_core_choice:-1}

    case "${argo_core_choice}" in
        1) ARGO_CORE_TYPE="xray" ;;
        2) ARGO_CORE_TYPE="sing-box" ;;
        *) print_error "核心选择错误"; return 1 ;;
    esac

    echo ""
    echo -e "选择协议:"
    echo -e "  ${GREEN}[1]${NC} VMess"
    echo -e "  ${GREEN}[2]${NC} VLESS"
    echo ""
    read -p "请选择 (1-2, 默认1): " argo_proto_choice
    argo_proto_choice=${argo_proto_choice:-1}

    case "${argo_proto_choice}" in
        1) ARGO_PROTOCOL="1" ;;
        2) ARGO_PROTOCOL="2" ;;
        *) print_error "协议选择错误"; return 1 ;;
    esac

    echo ""
    echo -e "选择 IP 版本:"
    echo -e "  ${GREEN}[4]${NC} IPv4"
    echo -e "  ${GREEN}[6]${NC} IPv6"
    echo ""
    read -p "请选择 (4 或 6, 默认4): " argo_ips_choice
    argo_ips_choice=${argo_ips_choice:-4}

    case "${argo_ips_choice}" in
        4) ARGO_IPS="4" ;;
        6) ARGO_IPS="6" ;;
        *) print_error "IP 版本选择错误"; return 1 ;;
    esac

    ARGO_ISP=$(curl -s$argo_ips_choice "https://speed.cloudflare.com/meta" | awk -F\" '{print $26"-"$18"-"$30}' | sed 's/ /_/g')
    if [[ -z "$ARGO_ISP" ]]; then
        ARGO_ISP="Argo_Node"
    fi

    argo_menu
}

# ==================== 主入口 ====================

main() {
    mkdir -p "${CONFIG_DIR}" "${LINK_DIR}"

    detect_system
    detect_init_system
    load_core_type
    get_ip
    load_all_links

    while true; do
        show_main_menu

        echo ""
        read -p "请选择操作 (0-8): " main_choice
        echo ""

        case "${main_choice}" in
            1)
                show_protocol_menu
                ;;
            2)
                setup_relay
                ;;
            3)
                display_all_links
                echo ""
                read -p "按回车键继续..."
                ;;
            4)
                regenerate_all_links
                ;;
            5)
                switch_core_type
                ;;
            6)
                setup_argo
                ;;
            7)
                show_system_tools
                ;;
            8)
                show_core_management
                ;;
            0)
                echo ""
                echo -e "${GREEN}感谢使用 Proxy Toolkit！${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "无效选择，请输入 0-8"
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

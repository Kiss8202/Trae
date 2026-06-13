# ==================== sing-box DNS配置模块 ====================
# ==================== DNS 配置管理 ====================
DNS_MODE="udp"
DNS_SERVER="8.8.8.8"
DNS_SERVER_NAME="Google"

save_dns_config() {
    mkdir -p "$(dirname "${DNS_CONFIG_FILE}")"
    cat > "${DNS_CONFIG_FILE}" << EOF
# Sing-box DNS 配置
DNS_MODE="${DNS_MODE}"
DNS_SERVER="${DNS_SERVER}"
DNS_SERVER_NAME="${DNS_SERVER_NAME}"
EOF
}

load_dns_config() {
    if [[ -f "${DNS_CONFIG_FILE}" ]] && [[ -r "${DNS_CONFIG_FILE}" ]]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            value="${value#\"}"
            value="${value%\"}"
            case "$key" in
                DNS_MODE) DNS_MODE="$value" ;;
                DNS_SERVER) DNS_SERVER="$value" ;;
                DNS_SERVER_NAME) DNS_SERVER_NAME="$value" ;;
            esac
        done < "${DNS_CONFIG_FILE}"
    fi
}

# 根据当前 DNS 配置生成 sing-box DNS server JSON
build_dns_remote_server() {
    case "${DNS_MODE}" in
        "doh")
            if [[ $SB_GE_1_12 -eq 1 ]]; then
                echo "{\"tag\": \"remote\", \"type\": \"https\", \"server\": \"${DNS_SERVER}\", \"server_port\": 443, \"domain_resolver\": \"local\"}"
            else
                echo "{\"tag\": \"remote\", \"type\": \"https\", \"server\": \"${DNS_SERVER}\", \"server_port\": 443, \"address_resolver\": \"local\"}"
            fi
            ;;
        "dot")
            if [[ $SB_GE_1_12 -eq 1 ]]; then
                echo "{\"tag\": \"remote\", \"type\": \"tls\", \"server\": \"${DNS_SERVER}\", \"server_port\": 853, \"domain_resolver\": \"local\"}"
            else
                echo "{\"tag\": \"remote\", \"type\": \"tls\", \"server\": \"${DNS_SERVER}\", \"server_port\": 853, \"address_resolver\": \"local\"}"
            fi
            ;;
        "udp"|*)
            echo "{\"tag\": \"remote\", \"type\": \"udp\", \"server\": \"${DNS_SERVER}\"}"
            ;;
    esac
}

# DNS 配置菜单
dns_config_menu() {
    while true; do
        echo ""
        menu_header "DNS 配置"
        echo -e "${YELLOW}当前 DNS 模式:${NC} ${GREEN}${DNS_MODE^^}${NC}"
        echo -e "${YELLOW}当前 DNS 服务器:${NC} ${GREEN}${DNS_SERVER_NAME} (${DNS_SERVER})${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} UDP 模式 (默认，兼容性最好)"
        echo -e "  ${GREEN}[2]${NC} DNS-over-HTTPS (DoH，加密DNS查询)"
        echo -e "  ${GREEN}[3]${NC} DNS-over-TLS (DoT，加密DNS查询)"
        echo -e "  ${GREEN}[4]${NC} 自定义 DNS 服务器"
        echo -e "  ${GREEN}[5]${NC} 预设 DNS 服务器列表"
        echo -e "  ${GREEN}[0]${NC} 返回主菜单"
        echo ""
        read -p "请选择 [0-5]: " dns_choice

        case $dns_choice in
            1)
                DNS_MODE="udp"
                save_dns_config
                print_success "DNS 模式已设置为 UDP"
                ;;
            2)
                DNS_MODE="doh"
                save_dns_config
                print_success "DNS 模式已设置为 DoH"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                ;;
            3)
                DNS_MODE="dot"
                save_dns_config
                print_success "DNS 模式已设置为 DoT"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                ;;
            4)
                read -p "请输入 DNS 服务器地址 (域名，如 dns.google): " custom_dns
                if [[ -n "$custom_dns" ]]; then
                    DNS_SERVER="$custom_dns"
                    DNS_SERVER_NAME="Custom"
                    save_dns_config
                    print_success "DNS 服务器已设置为: ${DNS_SERVER}"
                fi
                ;;
            5)
                echo ""
                echo -e "${CYAN}预设 DNS 服务器:${NC}"
                echo -e "  ${GREEN}[1]${NC} Google (8.8.8.8 / dns.google)"
                echo -e "  ${GREEN}[2]${NC} Cloudflare (1.1.1.1 / cloudflare-dns.com)"
                echo -e "  ${GREEN}[3]${NC} Alibaba (223.5.5.5 / dns.alidns.com)"
                echo -e "  ${GREEN}[4]${NC} Tencent (119.29.29.29 / doh.pub)"
                echo -e "  ${GREEN}[0]${NC} 取消"
                echo ""
                read -p "请选择: " preset_choice
                case $preset_choice in
                    1) DNS_SERVER="8.8.8.8"; DNS_SERVER_NAME="Google"; DNS_MODE="udp"; save_dns_config; print_success "已设置为 Google DNS" ;;
                    2) DNS_SERVER="cloudflare-dns.com"; DNS_SERVER_NAME="Cloudflare"; DNS_MODE="doh"; save_dns_config; print_success "已设置为 Cloudflare DoH" ;;
                    3) DNS_SERVER="dns.alidns.com"; DNS_SERVER_NAME="Alibaba"; DNS_MODE="doh"; save_dns_config; print_success "已设置为 Alibaba DoH" ;;
                    4) DNS_SERVER="doh.pub"; DNS_SERVER_NAME="Tencent"; DNS_MODE="doh"; save_dns_config; print_success "已设置为 Tencent DoH" ;;
                    *) continue ;;
                esac
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac

        # 询问是否立即应用
        if [[ "$dns_choice" =~ ^[1-5]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
            read -p "是否立即重新生成配置? (y/N): " regen
            if [[ "$regen" =~ ^[Yy]$ ]]; then
                generate_config && start_svc
            fi
        fi
    done
}

# ==================== IP 配置管理 ====================
save_ip_config() {
    mkdir -p "$(dirname "${IP_CONFIG_FILE}")"
    cat > "${IP_CONFIG_FILE}" << EOF
# Sing-box IP 配置
SERVER_IP="${SERVER_IP}"
SERVER_IPV6="${SERVER_IPV6}"
INBOUND_IP_MODE="${INBOUND_IP_MODE}"
OUTBOUND_IP_MODE="${OUTBOUND_IP_MODE}"
EOF
}

load_ip_config() {
    if [[ -f "${IP_CONFIG_FILE}" ]] && [[ -r "${IP_CONFIG_FILE}" ]]; then
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            # 去除值两端的引号
            value="${value#\"}"
            value="${value%\"}"
            case "$key" in
                SERVER_IP) SERVER_IP="$value" ;;
                SERVER_IPV6) SERVER_IPV6="$value" ;;
                INBOUND_IP_MODE) INBOUND_IP_MODE="$value" ;;
                OUTBOUND_IP_MODE) OUTBOUND_IP_MODE="$value" ;;
            esac
        done < "${IP_CONFIG_FILE}"
    fi
}

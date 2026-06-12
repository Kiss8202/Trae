# ==================== sing-box 配置生成模块 ====================
# ==================== 出入站 IP 配置菜单 ====================
ip_config_menu() {
    while true; do
        clear
        menu_header "出入站 IP 配置"
        echo -e "${YELLOW}当前配置:${NC}"
        echo -e "  IPv4 地址: ${GREEN}${SERVER_IP}${NC}"
        [[ -n "$SERVER_IPV6" ]] && echo -e "  IPv6 地址: ${GREEN}${SERVER_IPV6}${NC}"
        echo -e "  入站模式: ${GREEN}${INBOUND_IP_MODE}${NC}"
        echo -e "  出站模式: ${GREEN}${OUTBOUND_IP_MODE}${NC}"
        echo ""
        echo -e "${CYAN}说明:${NC}"
        echo -e "  ${YELLOW}入站${NC}: 控制节点监听的 IP 版本（客户端连接到哪个 IP）"
        echo -e "  ${YELLOW}出站${NC}: 控制服务器对外连接的 IP 版本（访问网站用哪个 IP）"
        echo ""
        echo -e "  ${GREEN}[1]${NC} 设置入站为 IPv4"
        echo -e "  ${GREEN}[2]${NC} 设置入站为 IPv6"
        echo -e "  ${GREEN}[3]${NC} 设置入站为双栈 (IPv4+IPv6)"
        echo -e "  ${GREEN}[4]${NC} 设置出站为 IPv4"
        echo -e "  ${GREEN}[5]${NC} 设置出站为 IPv6 (优先)"
        echo -e "  ${GREEN}[6]${NC} 设置出站为仅 IPv6 (IPv4不出站)"
        echo -e "  ${GREEN}[7]${NC} 设置出站为双栈 (IPv4+IPv6)"
        echo -e "  ${GREEN}[8]${NC} 手动修改 IPv4 地址"
        echo -e "  ${GREEN}[9]${NC} 手动修改 IPv6 地址"
        echo -e "  ${GREEN}[0]${NC} 返回主菜单"
        echo ""
        read -p "请选择 [0-9]: " ip_choice
        
        case $ip_choice in
            1)
                INBOUND_IP_MODE="ipv4"
                save_ip_config
                print_success "入站已设置为 IPv4"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            2)
                if [[ -z "$SERVER_IPV6" ]]; then
                    print_error "未检测到 IPv6 地址，请先手动设置"
                    pause
                    continue
                fi
                INBOUND_IP_MODE="ipv6"
                save_ip_config
                print_success "入站已设置为 IPv6"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            3)
                INBOUND_IP_MODE="dual"
                save_ip_config
                print_success "入站已设置为双栈 (IPv4+IPv6)"
                echo -e "${YELLOW}提示: 双栈模式将同时监听 IPv4 和 IPv6${NC}"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            4)
                OUTBOUND_IP_MODE="ipv4"
                save_ip_config
                print_success "出站已设置为 IPv4"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            5)
                if [[ -z "$SERVER_IPV6" ]]; then
                    print_error "未检测到 IPv6 地址，请先手动设置"
                    pause
                    continue
                fi
                OUTBOUND_IP_MODE="ipv6"
                save_ip_config
                print_success "出站已设置为 IPv6 优先"
                echo -e "${YELLOW}提示: IPv6 优先出站，IPv6 不可用时回退到 IPv4${NC}"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            6)
                if [[ -z "$SERVER_IPV6" ]]; then
                    print_error "未检测到 IPv6 地址，请先手动设置"
                    pause
                    continue
                fi
                OUTBOUND_IP_MODE="ipv6_only"
                save_ip_config
                print_success "出站已设置为仅 IPv6"
                echo -e "${YELLOW}提示: 仅使用 IPv6 出站，IPv4 将无法出站${NC}"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            7)
                OUTBOUND_IP_MODE="dual"
                save_ip_config
                print_success "出站已设置为双栈 (IPv4+IPv6)"
                echo -e "${YELLOW}提示: 双栈模式将同时使用 IPv4 和 IPv6，由系统自动选择${NC}"
                echo -e "${YELLOW}提示: 需要重新生成配置才能生效${NC}"
                read -p "是否立即重新生成配置? (y/N): " regen
                if [[ "$regen" =~ ^[Yy]$ ]] && [[ -n "$INBOUNDS_JSON" ]]; then
                    generate_config && start_svc
                fi
                ;;
            8)
                read -p "请输入 IPv4 地址: " new_ipv4
                if [[ -n "$new_ipv4" ]]; then
                    SERVER_IP="$new_ipv4"
                    save_ip_config
                    print_success "IPv4 地址已更新: ${SERVER_IP}"
                    echo -e "${YELLOW}提示: 需要重新生成链接文件${NC}"
                fi
                ;;
            9)
                read -p "请输入 IPv6 地址: " new_ipv6
                if [[ -n "$new_ipv6" ]]; then
                    SERVER_IPV6="$new_ipv6"
                    save_ip_config
                    print_success "IPv6 地址已更新: ${SERVER_IPV6}"
                    echo -e "${YELLOW}提示: 需要重新生成链接文件${NC}"
                fi
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
        
        [[ "$ip_choice" != "0" ]] && pause
    done
}

# ==================== Reality 节点修改 ====================
modify_reality_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 Reality 节点:${NC}"
    local reality_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "Reality" ]]; then
            reality_nodes+=("$i")
            echo -e "  ${GREEN}[${#reality_nodes[@]}]${NC} 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#reality_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 Reality 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#reality_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${reality_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 Reality 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改 SNI (当前: ${INBOUND_SNIS[$array_idx]})"
        echo -e "  ${GREEN}[3]${NC} 重新生成 UUID"
        echo -e "  ${GREEN}[4]${NC} 重新生成 Short ID"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_tag=$(modify_port "$tag" "vless-in-" "$new_port")
                INBOUND_TAGS[$array_idx]="$new_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}"
                ;;
            2)
                echo -e "${YELLOW}新 SNI (留空随机)${NC}"
                echo -e "${CYAN}例如: ${DEFAULT_SNI1}${NC}"
                read -p "SNI: " new_sni
                if [[ -z "$new_sni" ]]; then
                    new_sni=$(get_random_sni)
                fi
                jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                    '(.inbounds[] | select(.tag == $tag)) |= (.tls.server_name = $sni | .tls.reality.handshake.server = $sni)'
                INBOUND_SNIS[$array_idx]="$new_sni"
                config_changed=1
                print_success "SNI 已修改为 ${new_sni}"
                ;;
            3)
                regenerate_secret uuid "$tag" || continue
                config_changed=1
                ;;
            4)
                regenerate_secret sid "$tag"
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== Hysteria2 节点修改 ====================
modify_hysteria2_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 Hysteria2 节点:${NC}"
    local hy2_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "Hysteria2" ]]; then
            hy2_nodes+=("$i")
            echo -e "  ${GREEN}[${#hy2_nodes[@]}]${NC} 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#hy2_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 Hysteria2 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#hy2_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${hy2_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    local current_sni="${INBOUND_SNIS[$array_idx]}"
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 Hysteria2 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改 SNI (当前: ${current_sni})"
        echo -e "  ${GREEN}[3]${NC} 重新生成密码"
        echo -e "  ${GREEN}[4]${NC} 重新生成混淆密码"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_tag=$(modify_port "$tag" "hy2-in-" "$new_port")
                INBOUND_TAGS[$array_idx]="$new_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}"
                ;;
            2)
                echo -e "${YELLOW}新 SNI (留空随机)${NC}"
                echo -e "${CYAN}例如: ${DEFAULT_SNI1}${NC}"
                read -p "SNI: " new_sni
                if [[ -z "$new_sni" ]]; then
                    new_sni=$(get_random_sni)
                fi
                jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                    '(.inbounds[] | select(.tag == $tag)) |= (.tls.server_name = $sni | .tls.certificate_path = ($sni | "/etc/sing-box/certs/\(.)" + "/cert.pem") | .tls.key_path = ($sni | "/etc/sing-box/certs/\(.)" + "/private.key"))'
                gen_cert_for_sni "${new_sni}"
                INBOUND_SNIS[$array_idx]="$new_sni"
                current_sni="$new_sni"
                config_changed=1
                print_success "SNI 已修改为 ${new_sni}，证书已重新生成"
                ;;
            3)
                regenerate_secret password "$tag"
                config_changed=1
                ;;
            4)
                regenerate_secret obfs_password "$tag"
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== SOCKS5 节点修改 ====================
modify_socks5_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 SOCKS5 节点:${NC}"
    local socks_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "SOCKS5" ]]; then
            socks_nodes+=("$i")
            echo -e "  ${GREEN}[${#socks_nodes[@]}]${NC} 端口: ${INBOUND_PORTS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#socks_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 SOCKS5 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#socks_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${socks_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    
    # 读取当前用户名
    local current_user=$(jq -r --arg tag "$tag" '(.inbounds[] | select(.tag == $tag)).users[0].username // ""' "${CONFIG_FILE}")
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 SOCKS5 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改用户名 (当前: ${current_user:-无})"
        echo -e "  ${GREEN}[3]${NC} 重新生成密码"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_tag=$(modify_port "$tag" "socks-in-" "$new_port")
                INBOUND_TAGS[$array_idx]="$new_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}"
                ;;
            2)
                echo -e "${YELLOW}新用户名 (留空随机生成)${NC}"
                read -p "用户名: " new_user
                if [[ -z "$new_user" ]]; then
                    new_user="user_$(openssl rand -hex 4)"
                fi
                jq_update_config --arg tag "$tag" --arg user "$new_user" \
                    '(.inbounds[] | select(.tag == $tag)) |= (.users[0].username = $user)'
                current_user="$new_user"
                config_changed=1
                print_success "用户名已修改为 ${new_user}"
                ;;
            3)
                regenerate_secret socks_password "$tag"
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== ShadowTLS 节点修改 ====================
modify_shadowtls_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 ShadowTLS 节点:${NC}"
    local stls_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "ShadowTLS v3" ]]; then
            stls_nodes+=("$i")
            echo -e "  ${GREEN}[${#stls_nodes[@]}]${NC} 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#stls_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 ShadowTLS 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#stls_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${stls_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    local current_sni="${INBOUND_SNIS[$array_idx]}"
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 ShadowTLS 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改 SNI (当前: ${current_sni})"
        echo -e "  ${GREEN}[3]${NC} 重新生成 ShadowTLS 密码"
        echo -e "  ${GREEN}[4]${NC} 重新生成 SS 密码"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_stls_tag="shadowtls-in-${new_port}"
                local new_ss_tag="shadowsocks-in-${new_port}"
                local old_ss_tag="shadowsocks-in-${port}"
                # Update shadowtls inbound tag, port, and detour
                jq_update_config --arg old_tag "$tag" --arg new_tag "$new_stls_tag" --argjson new_port "$new_port" --arg new_ss_tag "$new_ss_tag" \
                    '(.inbounds[] | select(.tag == $old_tag)) |= (.tag = $new_tag | .listen_port = $new_port | .detour = $new_ss_tag)'
                # Update shadowsocks inbound tag and detour reference
                jq_update_config --arg old_ss_tag "$old_ss_tag" --arg new_ss_tag "$new_ss_tag" \
                    '(.inbounds[] | select(.tag == $old_ss_tag)) |= (.tag = $new_ss_tag)'
                # Update route rules
                if jq -e '.route.rules' "${CONFIG_FILE}" >/dev/null 2>&1; then
                    jq_update_config --arg old_tag "$tag" --arg new_tag "$new_stls_tag" \
                        '(.route.rules[] | select(.inbound[]? == $old_tag)) |= (.inbound = [.inbound[] | if . == $old_tag then $new_tag else . end])'
                fi
                INBOUND_TAGS[$array_idx]="$new_stls_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_stls_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}，SS 标签和 detour 已同步更新"
                ;;
            2)
                echo -e "${YELLOW}新 SNI (留空随机)${NC}"
                echo -e "${CYAN}例如: ${DEFAULT_SNI1}${NC}"
                read -p "SNI: " new_sni
                if [[ -z "$new_sni" ]]; then
                    new_sni=$(get_random_sni)
                fi
                jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                    '(.inbounds[] | select(.tag == $tag)) |= (.handshake.server = $sni)'
                INBOUND_SNIS[$array_idx]="$new_sni"
                current_sni="$new_sni"
                config_changed=1
                print_success "SNI 已修改为 ${new_sni}，handshake.server 已同步更新"
                ;;
            3)
                regenerate_secret stls_password "$tag"
                config_changed=1
                print_success "ShadowTLS 密码已重新生成"
                ;;
            4)
                local ss_tag="shadowsocks-in-${port}"
                regenerate_secret ss_password "$ss_tag"
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== HTTPS 节点修改 ====================
modify_https_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 HTTPS 节点:${NC}"
    local https_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "HTTPS" ]]; then
            https_nodes+=("$i")
            echo -e "  ${GREEN}[${#https_nodes[@]}]${NC} 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#https_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 HTTPS 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#https_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${https_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    local current_sni="${INBOUND_SNIS[$array_idx]}"
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 HTTPS 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改 SNI (当前: ${current_sni})"
        echo -e "  ${GREEN}[3]${NC} 重新生成 UUID"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_tag=$(modify_port "$tag" "vless-tls-in-" "$new_port")
                INBOUND_TAGS[$array_idx]="$new_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}"
                ;;
            2)
                echo -e "${YELLOW}新 SNI (留空随机)${NC}"
                echo -e "${CYAN}例如: ${DEFAULT_SNI1}${NC}"
                read -p "SNI: " new_sni
                if [[ -z "$new_sni" ]]; then
                    new_sni=$(get_random_sni)
                fi
                jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                    '(.inbounds[] | select(.tag == $tag)) |= (.tls.server_name = $sni | .tls.certificate_path = ($sni | "/etc/sing-box/certs/\(.)" + "/cert.pem") | .tls.key_path = ($sni | "/etc/sing-box/certs/\(.)" + "/private.key"))'
                gen_cert_for_sni "${new_sni}"
                INBOUND_SNIS[$array_idx]="$new_sni"
                current_sni="$new_sni"
                config_changed=1
                print_success "SNI 已修改为 ${new_sni}，证书已重新生成"
                ;;
            3)
                regenerate_secret uuid "$tag" || continue
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== AnyTLS 节点修改 ====================
modify_anytls_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可修改的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前 AnyTLS 节点:${NC}"
    local anytls_nodes=()
    for i in "${!INBOUND_TAGS[@]}"; do
        if [[ "${INBOUND_PROTOS[$i]}" == "AnyTLS" || "${INBOUND_PROTOS[$i]}" == "AnyTLS+REALITY" ]]; then
            anytls_nodes+=("$i")
            echo -e "  ${GREEN}[${#anytls_nodes[@]}]${NC} 协议: ${INBOUND_PROTOS[$i]}, 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
        fi
    done
    
    if [[ ${#anytls_nodes[@]} -eq 0 ]]; then
        print_warning "没有找到 AnyTLS 节点"
        return 1
    fi
    
    read -p "请选择要修改的节点序号 (0 取消): " node_choice
    [[ "$node_choice" == "0" ]] && return 0
    local idx=$((10#$node_choice-1))
    if ! [[ "$node_choice" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= ${#anytls_nodes[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local array_idx="${anytls_nodes[$idx]}"
    local tag="${INBOUND_TAGS[$array_idx]}"
    local port="${INBOUND_PORTS[$array_idx]}"
    local current_sni="${INBOUND_SNIS[$array_idx]}"
    local proto="${INBOUND_PROTOS[$array_idx]}"
    
    # 判断是否为 AnyTLS+REALITY 模式
    local is_reality=0
    if [[ "$proto" == "AnyTLS+REALITY" ]]; then
        is_reality=1
    fi
    
    local config_changed=0
    
    while true; do
        echo ""
        echo -e "${CYAN}修改 ${proto} 节点 ${tag}:${NC}"
        echo -e "  ${GREEN}[1]${NC} 修改端口 (当前: ${port})"
        echo -e "  ${GREEN}[2]${NC} 修改 SNI (当前: ${current_sni})"
        echo -e "  ${GREEN}[3]${NC} 重新生成密码"
        echo -e "  ${GREEN}[0]${NC} 返回"
        read -p "请选择: " mod_choice
        
        case $mod_choice in
            1)
                echo -e "${YELLOW}新端口 (留空随机分配)${NC}"
                read -p "端口: " new_port
                if [[ -z "$new_port" ]]; then
                    new_port=$(get_random_free_port)
                    [[ -z "$new_port" ]] && { print_error "无法获取随机端口"; continue; }
                fi
                if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1 || new_port > 65535 )); then
                    print_error "端口无效"; continue
                fi
                if check_port_in_use "$new_port" && [[ "$new_port" != "$port" ]]; then
                    print_warning "端口 ${new_port} 已被占用"; continue
                fi
                local new_tag_prefix
                if [[ $is_reality -eq 1 ]]; then
                    new_tag_prefix="anytls-reality-"
                else
                    new_tag_prefix="anytls-in-"
                fi
                local new_tag=$(modify_port "$tag" "$new_tag_prefix" "$new_port")
                INBOUND_TAGS[$array_idx]="$new_tag"
                INBOUND_PORTS[$array_idx]="$new_port"
                tag="$new_tag"
                port="$new_port"
                config_changed=1
                print_success "端口已修改为 ${new_port}"
                ;;
            2)
                echo -e "${YELLOW}新 SNI (留空随机)${NC}"
                echo -e "${CYAN}例如: ${DEFAULT_SNI1}${NC}"
                read -p "SNI: " new_sni
                if [[ -z "$new_sni" ]]; then
                    new_sni=$(get_random_sni)
                fi
                if [[ $is_reality -eq 1 ]]; then
                    jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                        '(.inbounds[] | select(.tag == $tag)) |= (.tls.server_name = $sni | .tls.reality.handshake.server = $sni)'
                else
                    jq_update_config --arg tag "$tag" --arg sni "$new_sni" \
                        '(.inbounds[] | select(.tag == $tag)) |= (.tls.server_name = $sni | .tls.certificate_path = ($sni | "/etc/sing-box/certs/\(.)" + "/cert.pem") | .tls.key_path = ($sni | "/etc/sing-box/certs/\(.)" + "/private.key"))'
                    gen_cert_for_sni "${new_sni}"
                fi
                INBOUND_SNIS[$array_idx]="$new_sni"
                current_sni="$new_sni"
                config_changed=1
                if [[ $is_reality -eq 1 ]]; then
                    print_success "SNI 已修改为 ${new_sni}，handshake.server 已同步更新"
                else
                    print_success "SNI 已修改为 ${new_sni}，证书已重新生成"
                fi
                ;;
            3)
                regenerate_secret password "$tag"
                config_changed=1
                ;;
            0)
                break
                ;;
            *)
                print_error "无效选项"
                ;;
        esac
    done
    
    if [[ $config_changed -eq 1 ]]; then
        load_inbounds_from_config
        generate_config && start_svc
        regenerate_links_from_config
    fi
}

# ==================== 节点删除功能 ====================
delete_single_node() {
    if [[ ${#INBOUND_TAGS[@]} -eq 0 ]]; then
        print_warning "当前没有可删除的节点"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}当前节点列表:${NC}"
    for i in "${!INBOUND_TAGS[@]}"; do
        idx=$((i+1))
        echo -e "  ${GREEN}[${idx}]${NC} 协议: ${INBOUND_PROTOS[$i]}, 端口: ${INBOUND_PORTS[$i]}, SNI: ${INBOUND_SNIS[$i]}, TAG: ${INBOUND_TAGS[$i]}"
    done
    echo ""
    echo -e "${RED}警告: 删除节点后无法恢复！${NC}"
    read -p "请输入要删除的节点序号 (输入 0 取消): " node_idx
    
    if [[ "$node_idx" == "0" ]]; then
        print_info "取消删除操作"
        return 0
    fi
    
    if ! [[ "$node_idx" =~ ^[0-9]+$ ]] || (( node_idx < 1 || node_idx > ${#INBOUND_TAGS[@]} )); then
        print_error "序号无效"
        return 1
    fi
    
    local index=$((node_idx-1))
    local tag="${INBOUND_TAGS[$index]}"
    local port="${INBOUND_PORTS[$index]}"
    local proto="${INBOUND_PROTOS[$index]}"
    local sni="${INBOUND_SNIS[$index]}"
    
    echo ""
    echo -e "${YELLOW}确认删除以下节点:${NC}"
    echo -e "  协议: ${proto}"
    echo -e "  端口: ${port}"
    echo -e "  SNI: ${sni}"
    echo -e "  TAG: ${tag}"
    echo ""

    if ! confirm "确认删除? (y/N): "; then
        print_info "取消删除操作"
        return 0
    fi
    
    # 从配置文件中删除节点
    if [[ -f "${CONFIG_FILE}" ]] && command -v jq &>/dev/null; then
        print_info "从配置文件删除节点..."
        
        # 使用 jq 过滤掉要删除的节点
        local temp_config=$(mktemp)
        
        # 如果是 ShadowTLS，需要同时删除对应的 shadowsocks-in 节点
        if [[ "$proto" == "ShadowTLS v3" ]]; then
            local ss_tag="shadowsocks-in-${port}"
            jq --arg tag "$tag" --arg ss_tag "$ss_tag" '.inbounds |= map(select(.tag != $tag and .tag != $ss_tag))' "${CONFIG_FILE}" > "$temp_config"
        else
            jq --arg tag "$tag" '.inbounds |= map(select(.tag != $tag))' "${CONFIG_FILE}" > "$temp_config"
        fi
        
        mv "$temp_config" "${CONFIG_FILE}"
        
        # 从数组中删除
        unset INBOUND_TAGS[$index]
        unset INBOUND_PORTS[$index]
        unset INBOUND_PROTOS[$index]
        unset INBOUND_SNIS[$index]
        unset INBOUND_RELAY_TAGS[$index]
        
        # 重建数组（移除空元素）
        INBOUND_TAGS=("${INBOUND_TAGS[@]}")
        INBOUND_PORTS=("${INBOUND_PORTS[@]}")
        INBOUND_PROTOS=("${INBOUND_PROTOS[@]}")
        INBOUND_SNIS=("${INBOUND_SNIS[@]}")
        INBOUND_RELAY_TAGS=("${INBOUND_RELAY_TAGS[@]}")
        
        # 重新加载配置
        load_inbounds_from_config
        
        # 重新生成链接文件
        print_info "重新生成链接文件..."
        regenerate_links_from_config
        
        # 重启服务
        print_info "重启服务..."
        svc_restart
        sleep 2
        
        if svc_is_active; then
            print_success "节点已删除: ${proto}:${port} (SNI: ${sni})"
            print_success "服务已重启"
        else
            print_error "服务重启失败"
            if [[ $ALPINE -eq 1 ]]; then
                tail -n 10 /var/log/messages | grep sing-box || cat /var/log/sing-box.log 2>/dev/null
            else
                journalctl -u sing-box -n 10 --no-pager
            fi
        fi
    else
        print_error "无法删除节点：配置文件不存在或 jq 未安装"
        return 1
    fi
}

delete_all_nodes() {
    echo ""
    echo -e "${RED}⚠️  警告: 此操作将删除所有节点配置！${NC}"
    echo -e "${YELLOW}当前共有 ${#INBOUND_TAGS[@]} 个节点${NC}"
    echo ""
    echo -e "删除后:"
    echo -e "  1. 所有节点配置将被清空"
    echo -e "  2. 配置文件将只保留基础结构"
    echo -e "  3. 需要重新添加节点"
    echo ""
    
    if ! confirm "确认删除所有节点? (y/N): "; then
        print_info "取消删除操作"
        return 0
    fi
    
    INBOUNDS_JSON=""
    INBOUND_TAGS=()
    INBOUND_PORTS=()
    INBOUND_PROTOS=()
    INBOUND_SNIS=()
    INBOUND_RELAY_TAGS=()
    
    # 根据出站模式设置 DNS 策略
    local dns_strategy="prefer_ipv4"
    [[ "$OUTBOUND_IP_MODE" == "ipv6" ]] && dns_strategy="prefer_ipv6"
    [[ "$OUTBOUND_IP_MODE" == "ipv6_only" ]] && dns_strategy="ipv6_only"

    local dns_domain_resolver=""
    if [[ $SB_GE_1_12 -eq 1 ]]; then
        dns_domain_resolver=",
    \"default_domain_resolver\": \"local\""
    fi

    # 根据用户配置的 DNS 模式生成远程 DNS 服务器配置
    local dns_remote_server
    dns_remote_server=$(build_dns_remote_server)

    cat > ${CONFIG_FILE} << EOFCONFIG
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "local",
        "type": "local"
      },
      ${dns_remote_server}
    ],
    "final": "remote",
    "strategy": "${dns_strategy}"${dns_domain_resolver}
  },
  "inbounds": [],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "final": "direct",
    "default_domain_resolver": "local"
  }
}
EOFCONFIG
    
    print_info "停止 sing-box 服务..."
    svc_stop
    
    cleanup_links
    
    print_success "所有节点已删除，配置文件已重置"
    
    read -p "是否启动空配置的 sing-box 服务? (y/N): " restart_service
    restart_service=${restart_service:-N}
    
    if [[ "$restart_service" =~ ^[Yy]$ ]]; then
        svc_start
        sleep 2
        if svc_is_active; then
            print_success "服务已启动 (空配置)"
        else
            print_error "服务启动失败"
        fi
    fi
}
# ==================== 配置生成（修复路由逻辑） ====================
generate_config() {
    print_info "生成最终配置文件..."

    if [[ -f "${CONFIG_FILE}" ]]; then
        local backup_file="${CONFIG_FILE}.bak"
        cp "${CONFIG_FILE}" "${backup_file}" 2>/dev/null
        print_info "已备份配置到: ${backup_file}"
    fi

    if [[ -z "$INBOUNDS_JSON" ]]; then
        print_error "未找到任何入站节点，请先添加节点"
        return 1
    fi
    
    # 加载中转配置
    load_relays_from_file
    
    # 构建 outbounds 数组
    local outbounds_array=()
    
    # 添加所有中转 outbound
    for relay_json in "${RELAY_JSONS[@]}"; do
        outbounds_array+=("$relay_json")
    done
    
    # 添加 direct outbound（根据出站模式设置绑定地址和域名解析策略）
    # sing-box 1.14.0+ 移除了 domain_strategy，需通过 domain_resolver 设置解析策略
    local direct_outbound
    if [[ "$OUTBOUND_IP_MODE" == "ipv6" ]]; then
        # IPv6优先：绑定IPv6地址 + domain_resolver策略prefer_ipv6，IPv6不可用时回退IPv4
        if [[ -n "${SERVER_IPV6}" ]]; then
            direct_outbound="{\"type\": \"direct\", \"tag\": \"direct\", \"tcp_fast_open\": false, \"inet6_bind_address\": \"${SERVER_IPV6}\", \"fallback_delay\": \"300ms\", \"domain_resolver\": {\"server\": \"remote\", \"strategy\": \"prefer_ipv6\"}}"
        else
            direct_outbound='{"type": "direct", "tag": "direct", "tcp_fast_open": false, "domain_resolver": {"server": "remote", "strategy": "prefer_ipv6"}}'
        fi
    elif [[ "$OUTBOUND_IP_MODE" == "ipv6_only" ]]; then
        # 仅IPv6：绑定IPv6地址 + domain_resolver策略ipv6_only，配合block规则彻底阻断IPv4
        if [[ -n "${SERVER_IPV6}" ]]; then
            direct_outbound="{\"type\": \"direct\", \"tag\": \"direct\", \"tcp_fast_open\": false, \"inet6_bind_address\": \"${SERVER_IPV6}\", \"domain_resolver\": {\"server\": \"remote\", \"strategy\": \"ipv6_only\"}}"
        else
            direct_outbound='{"type": "direct", "tag": "direct", "tcp_fast_open": false, "domain_resolver": {"server": "remote", "strategy": "ipv6_only"}}'
        fi
    elif [[ "$OUTBOUND_IP_MODE" == "ipv4" ]]; then
        # 仅IPv4：绑定IPv4地址 + domain_resolver策略ipv4_only
        if [[ -n "${SERVER_IP}" ]]; then
            direct_outbound="{\"type\": \"direct\", \"tag\": \"direct\", \"tcp_fast_open\": false, \"inet4_bind_address\": \"${SERVER_IP}\", \"domain_resolver\": {\"server\": \"remote\", \"strategy\": \"ipv4_only\"}}"
        else
            direct_outbound='{"type": "direct", "tag": "direct", "tcp_fast_open": false, "domain_resolver": {"server": "remote", "strategy": "ipv4_only"}}'
        fi
    else
        # dual 双栈：不限制绑定地址
        direct_outbound='{"type": "direct", "tag": "direct", "tcp_fast_open": false}'
    fi
    outbounds_array+=("$direct_outbound")
    
    # ipv6_only 模式下阻断 IPv4 出站
    # 注意: sing-box 1.13.0+ 已移除 block outbound，改用 route rule action
    if [[ "$OUTBOUND_IP_MODE" == "ipv6_only" ]]; then
        if [[ $SB_GE_1_13 -eq 1 ]]; then
            # 1.13.0+ 不添加 block outbound，在路由规则中用 action 处理
            :
        else
            # 旧版本使用 block outbound
            local block_outbound='{"type": "block", "tag": "block-ipv4"}'
            outbounds_array+=("$block_outbound")
        fi
    fi
    
    # 组合 outbounds
    local outbounds="["
    for i in "${!outbounds_array[@]}"; do
        [[ $i -gt 0 ]] && outbounds+=", "
        outbounds+="${outbounds_array[$i]}"
    done
    outbounds+="]"
    
    # 加载分流规则
    load_domain_routes_from_file
    
    # 构建路由规则
    local route_rules=()
    local has_relay=0

    # 添加协议嗅探规则（1.13.0+ 使用 route rule action，旧版使用 inbound sniff 字段）
    if [[ $SB_GE_1_13 -eq 1 ]]; then
        route_rules+=('{"action":"sniff","protocols":["http","tls","quic"]}')
        has_relay=1
    fi

    # ipv6_only 模式下，添加规则阻断所有 IPv4 出站流量
    if [[ "$OUTBOUND_IP_MODE" == "ipv6_only" ]]; then
        if [[ $SB_GE_1_13 -eq 1 ]]; then
            # 1.13.0+ 使用 route rule action
            route_rules+=('{"ip_cidr":["0.0.0.0/0"],"action":"block"}')
        else
            route_rules+=('{"ip_cidr":["0.0.0.0/0"],"outbound":"block-ipv4"}')
        fi
        has_relay=1
    fi
    
    # 1. 首先添加所有分流域名规则（无论节点默认是中转还是直连）
    for route in "${DOMAIN_ROUTES[@]}"; do
        IFS='|' read -r inbound_tag match_type match_value relay_tag desc <<< "$route"
        [[ -z "$inbound_tag" || -z "$match_type" || -z "$match_value" || -z "$relay_tag" ]] && continue
        
        # 检查中转是否存在
        local relay_exists=0
        for rt in "${RELAY_TAGS[@]}"; do
            if [[ "$rt" == "$relay_tag" ]]; then
                relay_exists=1
                break
            fi
        done
        if [[ $relay_exists -eq 0 ]]; then
            print_warning "分流规则引用的中转 ${relay_tag} 不存在，跳过规则: ${match_type}=${match_value}"
            continue
        fi
        
        # 根据匹配类型生成对应的 sing-box 规则
        local rule_part=""
        case "$match_type" in
            domain_suffix)
                rule_part="\"domain_suffix\":[\"${match_value}\"]"
                ;;
            domain)
                rule_part="\"domain\":[\"${match_value}\"]"
                ;;
            domain_keyword)
                rule_part="\"domain_keyword\":[\"${match_value}\"]"
                ;;
            ip_cidr)
                rule_part="\"ip_cidr\":[\"${match_value}\"]"
                ;;
            *)
                continue
                ;;
        esac
        
        route_rules+=("{\"inbound\":[\"${inbound_tag}\"],${rule_part},\"outbound\":\"${relay_tag}\"}")
        has_relay=1
    done
    
    # 2. 为每个节点添加默认路由（仅当节点配置了中转且不是 direct）
    for i in "${!INBOUND_TAGS[@]}"; do
        local inbound_tag="${INBOUND_TAGS[$i]}"
        local relay_tag="${INBOUND_RELAY_TAGS[$i]}"
        
        # 如果节点配置了具体的中转（非 direct），则添加兜底规则
        if [[ "$relay_tag" != "direct" ]]; then
            # 检查中转是否存在
            local relay_exists=0
            for rt in "${RELAY_TAGS[@]}"; do
                if [[ "$rt" == "$relay_tag" ]]; then
                    relay_exists=1
                    break
                fi
            done
            if [[ $relay_exists -eq 0 ]]; then
                print_warning "节点 ${inbound_tag} 配置的中转 ${relay_tag} 不存在，将改为直连"
                INBOUND_RELAY_TAGS[$i]="direct"
                continue
            fi
            route_rules+=("{\"inbound\":[\"${inbound_tag}\"],\"outbound\":\"${relay_tag}\"}")
            has_relay=1
        fi
    done
    
    # 组合路由配置
    local route_json
    local route_domain_resolver=""
    if [[ $SB_GE_1_12 -eq 1 ]]; then
        route_domain_resolver=",\"default_domain_resolver\":\"local\""
    else
        route_domain_resolver=",\"default_domain_resolver\":\"local\""
    fi
    if [[ $has_relay -eq 1 ]]; then
        route_json="{\"rules\":["
        for i in "${!route_rules[@]}"; do
            [[ $i -gt 0 ]] && route_json+=","
            route_json+="${route_rules[$i]}"
        done
        route_json+="],\"final\":\"direct\"${route_domain_resolver}}"
    else
        route_json="{\"final\":\"direct\"${route_domain_resolver}}"
    fi
    
    # 构建 DNS 配置（根据出站 IP 模式和 DNS 模式）
    # sing-box 1.12.0+ 重构了 DNS 配置，1.14.0 将移除旧格式兼容
    local dns_json
    local dns_strategy="prefer_ipv4"
    [[ "$OUTBOUND_IP_MODE" == "ipv6" ]] && dns_strategy="prefer_ipv6"
    [[ "$OUTBOUND_IP_MODE" == "ipv6_only" ]] && dns_strategy="ipv6_only"

    # 根据用户配置的 DNS 模式生成远程 DNS 服务器配置
    local dns_remote_server
    dns_remote_server=$(build_dns_remote_server)

    if [[ $SB_GE_1_12 -eq 1 ]]; then
        # 1.12.0+ 新 DNS 格式（兼容 1.14.0）
        dns_json="{
    \"servers\": [
      {
        \"tag\": \"local\",
        \"type\": \"local\"
      },
      ${dns_remote_server}
    ],
    \"final\": \"remote\",
    \"strategy\": \"${dns_strategy}\",
    \"default_domain_resolver\": \"local\"
  }"
    else
        # 旧版本 DNS 格式
        dns_json="{
    \"servers\": [
      {
        \"tag\": \"local\",
        \"type\": \"local\"
      },
      ${dns_remote_server}
    ],
    \"final\": \"remote\",
    \"strategy\": \"${dns_strategy}\"
  }"
    fi
    
    cat > ${CONFIG_FILE} << EOFCONFIG
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": ${dns_json},
  "inbounds": [${INBOUNDS_JSON}],
  "outbounds": ${outbounds},
  "route": ${route_json}
}
EOFCONFIG
    
    print_success "配置文件生成完成"
}

start_svc() {
    print_info "验证配置文件..."
    
    local check_output
    check_output=$("${INSTALL_DIR}/sing-box" check -c "${CONFIG_FILE}" 2>&1)
    local check_exit_code=$?
    
    if [[ $check_exit_code -ne 0 ]]; then
        print_error "配置验证失败 (退出码: ${check_exit_code})"
        echo -e "${YELLOW}错误详情:${NC}"
        echo "$check_output"
        echo ""
        # 自动回滚到备份配置
        if [[ -f "${CONFIG_FILE}.bak" ]]; then
            print_warning "正在自动回滚到备份配置..."
            cp "${CONFIG_FILE}.bak" "${CONFIG_FILE}"
            print_success "已回滚到备份配置"
            # 尝试用备份配置重启
            if "${INSTALL_DIR}/sing-box" check -c "${CONFIG_FILE}" >/dev/null 2>&1; then
                print_info "使用备份配置重启服务..."
                svc_restart
                sleep 2
                if svc_is_active; then
                    print_success "服务已使用备份配置恢复运行"
                fi
            fi
        fi
        return 1
    fi
    
    if echo "$check_output" | grep -q "WARN"; then
        print_warning "配置验证通过，但有警告："
        echo "$check_output" | grep "WARN"
        echo ""
    else
        print_success "配置验证通过"
    fi
    
    print_info "启动 sing-box 服务..."
    svc_restart
    sleep 2
    
    if svc_is_active; then
        print_success "服务启动成功"
    else
        print_error "服务启动失败，查看日志："
        if [[ $ALPINE -eq 1 ]]; then
            tail -n 10 /var/log/messages | grep sing-box || cat /var/log/sing-box.log 2>/dev/null
        else
            journalctl -u sing-box -n 10 --no-pager
        fi
        return 1
    fi
}
# ==================== 结果显示 ====================
show_result() {
    clear
    echo ""
    menu_header "配置完成！"
    echo -e "${YELLOW}服务器信息:${NC}"
    echo -e "  协议: ${GREEN}${PROTO}${NC}"
    echo -e "  IP: ${GREEN}${SERVER_IP}${NC}"
    echo -e "  端口: ${GREEN}${PORT}${NC}"
    echo ""
    
    if [[ -n "$EXTRA_INFO" ]]; then
        echo -e "${YELLOW}协议详情:${NC}"
        echo -e "$EXTRA_INFO" | sed 's/^/  /'
        echo ""
    fi
    
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}📋 新添加的节点链接:${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo ""
    # 只显示新添加的节点链接
    if [[ -n "$CURRENT_NEW_LINKS" ]]; then
        echo -e "${YELLOW}${CURRENT_NEW_LINKS}${NC}"
    else
        echo -e "${YELLOW}${LINK}${NC}"
    fi
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${CYAN}💡 提示: 去菜单的 [配置与查看] 可以查看全部节点链接${NC}"
}

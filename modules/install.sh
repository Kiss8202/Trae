# ==================== sing-box 安装模块 ====================
# ==================== 安装 sing-box ====================
install_singbox() {
    print_info "检查 sing-box 安装状态（支持断点续装）..."

    # ---------- 1. 安装系统依赖 ----------
    local missing_deps=()
    for cmd in jq curl wget openssl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_info "缺少依赖: ${missing_deps[*]}，开始安装..."
        if [[ $ALPINE -eq 1 ]]; then
            # libcap 提供 setcap，降权运行 sing-box 绑定 443 等低端口必须
            for pkg in curl wget jq openssl util-linux coreutils iproute2 gcompat libcap; do
                if ! apk add --no-cache "$pkg" >/dev/null 2>&1; then
                    print_warning "包 ${pkg} 安装失败，继续尝试其他包..."
                fi
                sleep 0.5
            done
        else
            apt-get update -qq && apt-get install -y curl wget jq openssl uuid-runtime libcap2-bin >/dev/null 2>&1
        fi

        # 验证关键依赖是否安装成功
        local still_missing=()
        for cmd in jq curl wget openssl; do
            if ! command -v "$cmd" &>/dev/null; then
                still_missing+=("$cmd")
            fi
        done
        if [[ ${#still_missing[@]} -gt 0 ]]; then
            print_error "以下依赖安装失败: ${still_missing[*]}"
            return 1
        fi
        print_success "依赖安装完成"
    else
        print_success "基础依赖已就绪"
    fi

    # ---------- 2. 检查 sing-box 二进制是否可执行 ----------
    local need_download=1
    if [[ -x "${INSTALL_DIR}/sing-box" ]]; then
        # 尝试运行版本检查，若返回正常则认为可用
        if ${INSTALL_DIR}/sing-box version >/dev/null 2>&1; then
            local version=$(${INSTALL_DIR}/sing-box version 2>&1 | awk '/sing-box version/{print $3}' || echo "unknown")
            print_success "sing-box 已安装且可执行 (版本: ${version})"
            need_download=0
        else
            # sing-box 默认构建是纯 Go 静态编译，不需要 glibc 兼容层
            # 如果无法运行，可能是架构不匹配
            print_warning "检测到损坏的 sing-box，将重新下载安装"
            rm -f "${INSTALL_DIR}/sing-box"
        fi
    fi

    # ---------- 3. 下载、解压、安装二进制（如需要） ----------
    if [[ $need_download -eq 1 ]]; then
        local LATEST=""
        # sha256 校验值：来自 GitHub Release API 的 asset.digest 字段
        # （GitHub Release 不发布独立 .sha256 文件附件，但 API 元数据含 digest）
        local EXPECTED_SHA256=""
        local retry=0
        local max_retries=3
        while [[ $retry -lt $max_retries ]]; do
            local api_response
            api_response=$(curl -sf --connect-timeout 10 --max-time 30 "https://api.github.com/repos/SagerNet/sing-box/releases/latest" 2>/dev/null)
            if [[ -n "$api_response" ]]; then
                LATEST=$(echo "$api_response" | jq -r '.tag_name' 2>/dev/null | sed 's/v//')
                # 从 assets 提取对应架构的 sha256 digest（格式 "sha256:xxxx"，去掉前缀）
                EXPECTED_SHA256=$(echo "$api_response" | jq -r --arg name "sing-box-${LATEST}-linux-${ARCH}.tar.gz" \
                    '.assets[] | select(.name == $name) | .digest' 2>/dev/null | sed 's/^sha256://I' | tr -d '[:space:]')
            fi
            [[ -n "$LATEST" ]] && break
            ((retry++))
            print_warning "获取版本信息失败，重试 ${retry}/${max_retries}..."
            [[ $retry -lt $max_retries ]] && sleep 3
        done
        if [[ -z "$LATEST" ]]; then
            LATEST="1.13.12"
            print_warning "无法获取最新版本（网络问题或被墙），回退到已知稳定版本 ${LATEST}"
            print_warning "建议检查网络连接或设置 GH_MIRROR 环境变量"
            # 尝试获取 fallback 版本的 digest
            local fb_api
            fb_api=$(curl -sf --connect-timeout 10 --max-time 30 "https://api.github.com/repos/SagerNet/sing-box/releases/tags/v${LATEST}" 2>/dev/null)
            if [[ -n "$fb_api" ]]; then
                EXPECTED_SHA256=$(echo "$fb_api" | jq -r --arg name "sing-box-${LATEST}-linux-${ARCH}.tar.gz" \
                    '.assets[] | select(.name == $name) | .digest' 2>/dev/null | sed 's/^sha256//I' | tr -d '[:space:]')
            fi
        fi
        print_info "目标版本: ${LATEST}"

        # 清理可能残留的半成品
        rm -rf /tmp/sb.tar.gz /tmp/sing-box-${LATEST}-linux-${ARCH}
        TEMP_FILES+=("/tmp/sb.tar.gz" "/tmp/sing-box-${LATEST}-linux-${ARCH}")

        print_info "下载 sing-box (${LATEST} linux-${ARCH}) ..."
        local download_url="https://github.com/SagerNet/sing-box/releases/download/v${LATEST}/sing-box-${LATEST}-linux-${ARCH}.tar.gz"
        if ! wget -q --show-progress -O /tmp/sb.tar.gz "$download_url" 2>&1 || [[ ! -f /tmp/sb.tar.gz ]] || [[ ! -s /tmp/sb.tar.gz ]]; then
            print_error "下载失败，请检查网络后重新运行脚本"
            return 1
        fi
        # 验证下载的是 tar.gz 而非 404 HTML 页面
        if command -v file &>/dev/null; then
            local file_type
            file_type=$(file -b /tmp/sb.tar.gz 2>/dev/null)
            if [[ "$file_type" != *"gzip"* ]]; then
                print_error "下载的文件无效（可能是版本 ${LATEST} 不存在），尝试使用已知稳定版本"
                rm -f /tmp/sb.tar.gz
                # 回退到已知稳定版本
                LATEST="1.13.12"
                download_url="https://github.com/SagerNet/sing-box/releases/download/v${LATEST}/sing-box-${LATEST}-linux-${ARCH}.tar.gz"
                EXPECTED_SHA256=""  # 重置，下方重新获取
                local fb_api2
                fb_api2=$(curl -sf --connect-timeout 10 --max-time 30 "https://api.github.com/repos/SagerNet/sing-box/releases/tags/v${LATEST}" 2>/dev/null)
                if [[ -n "$fb_api2" ]]; then
                    EXPECTED_SHA256=$(echo "$fb_api2" | jq -r --arg name "sing-box-${LATEST}-linux-${ARCH}.tar.gz" \
                        '.assets[] | select(.name == $name) | .digest' 2>/dev/null | sed 's/^sha256//I' | tr -d '[:space:]')
                fi
                print_info "回退下载 sing-box (${LATEST} linux-${ARCH}) ..."
                if ! wget -q --show-progress -O /tmp/sb.tar.gz "$download_url" 2>&1 || [[ ! -f /tmp/sb.tar.gz ]] || [[ ! -s /tmp/sb.tar.gz ]]; then
                    print_error "下载失败，请检查网络后重新运行脚本"
                    return 1
                fi
                file_type=$(file -b /tmp/sb.tar.gz 2>/dev/null)
                if [[ "$file_type" != *"gzip"* ]]; then
                    print_error "下载的文件仍然无效，请检查网络或手动安装 sing-box"
                    rm -f /tmp/sb.tar.gz
                    return 1
                fi
            fi
        else
            # 没有 file 命令，用 tar 试解压来验证
            if ! tar -tzf /tmp/sb.tar.gz >/dev/null 2>&1; then
                print_error "下载的文件无效（可能是版本 ${LATEST} 不存在），尝试使用已知稳定版本"
                rm -f /tmp/sb.tar.gz
                LATEST="1.13.12"
                download_url="https://github.com/SagerNet/sing-box/releases/download/v${LATEST}/sing-box-${LATEST}-linux-${ARCH}.tar.gz"
                EXPECTED_SHA256=""
                local fb_api3
                fb_api3=$(curl -sf --connect-timeout 10 --max-time 30 "https://api.github.com/repos/SagerNet/sing-box/releases/tags/v${LATEST}" 2>/dev/null)
                if [[ -n "$fb_api3" ]]; then
                    EXPECTED_SHA256=$(echo "$fb_api3" | jq -r --arg name "sing-box-${LATEST}-linux-${ARCH}.tar.gz" \
                        '.assets[] | select(.name == $name) | .digest' 2>/dev/null | sed 's/^sha256//I' | tr -d '[:space:]')
                fi
                print_info "回退下载 sing-box (${LATEST} linux-${ARCH}) ..."
                if ! wget -q --show-progress -O /tmp/sb.tar.gz "$download_url" 2>&1 || [[ ! -f /tmp/sb.tar.gz ]] || [[ ! -s /tmp/sb.tar.gz ]]; then
                    print_error "下载失败，请检查网络后重新运行脚本"
                    return 1
                fi
            fi
        fi

        # 完整性校验：用 GitHub Release API 返回的 asset.digest 做严格 sha256 校验
        # （GitHub Release 不发布独立 .sha256 文件，但 API 元数据的 digest 字段就是官方 sha256）
        if [[ -n "$EXPECTED_SHA256" ]]; then
            local actual_hash
            actual_hash=$(sha256sum /tmp/sb.tar.gz | awk '{print $1}')
            if [[ "$EXPECTED_SHA256" == "$actual_hash" ]]; then
                print_success "sha256 校验通过（来自 GitHub Release API）"
            else
                print_error "sha256 校验失败（期望: ${EXPECTED_SHA256}, 实际: ${actual_hash}）"
                rm -f /tmp/sb.tar.gz
                return 1
            fi
        else
            # digest 不可得（API 限流或旧版本无 digest）：降级到完整性兜底验证
            # 兜底链：file/tar 类型检查（已做）→ tar 解压（下方）→ sing-box version 可执行（下方）
            print_warning "未获取到 sha256 校验值（API 限流），将使用完整性兜底验证（tar 解压 + 二进制可执行校验）"
        fi

        # 小内存机器解压时很可能被杀，解压前确保文件完整
        print_info "解压 sing-box ..."
        if tar -xzf /tmp/sb.tar.gz -C /tmp 2>/dev/null; then
            rm -f /tmp/sb.tar.gz
        else
            print_error "解压失败（可能内存不足被 kill），请增加 swap 后重新运行脚本"
            rm -f /tmp/sb.tar.gz
            return 1
        fi

        # 安装二进制
        if [[ -f "/tmp/sing-box-${LATEST}-linux-${ARCH}/sing-box" ]]; then
            install -Dm755 "/tmp/sing-box-${LATEST}-linux-${ARCH}/sing-box" "${INSTALL_DIR}/sing-box"
            rm -rf "/tmp/sing-box-${LATEST}-linux-${ARCH}"

            # 验证安装后的二进制是否可执行
            if ${INSTALL_DIR}/sing-box version >/dev/null 2>&1; then
                local version
                version=$(${INSTALL_DIR}/sing-box version 2>&1 | awk '/sing-box version/{print $3}' || echo "unknown")
                print_success "sing-box 二进制安装完成 (版本: ${version})"
            else
                # 输出详细诊断信息
                print_error "sing-box 安装后无法执行，诊断信息："
                echo -e "  系统架构: $(uname -m)"
                echo -e "  下载架构: linux-${ARCH}"
                echo -e "  文件大小: $(ls -l ${INSTALL_DIR}/sing-box 2>/dev/null | awk '{print $5}') bytes"
                if command -v file &>/dev/null; then
                    echo -e "  文件类型: $(file -b ${INSTALL_DIR}/sing-box 2>/dev/null)"
                fi
                # 尝试直接执行并捕获错误
                local exec_err
                exec_err=$(${INSTALL_DIR}/sing-box version 2>&1) || true
                echo -e "  执行错误: ${exec_err}"
                echo -e "  内核版本: $(uname -r)"

                # Alpine 缺少 glibc 兼容层时自动尝试安装 gcompat
                if [[ "$exec_err" == *"required file not found"* ]] && [[ $ALPINE -eq 1 ]]; then
                    print_info "检测到缺少 glibc 动态链接器，尝试安装 gcompat 兼容层..."
                    if apk add --no-cache gcompat libexecinfo >/dev/null 2>&1; then
                        print_success "gcompat 安装成功，重新验证 sing-box ..."
                        if ${INSTALL_DIR}/sing-box version >/dev/null 2>&1; then
                            local version=$(${INSTALL_DIR}/sing-box version 2>&1 | awk '/sing-box version/{print $3}' || echo "unknown")
                            print_success "sing-box 二进制安装完成 (版本: ${version})"
                            # 跳过 return 1，继续正常流程
                        else
                            print_error "安装 gcompat 后仍然无法执行"
                            return 1
                        fi
                    else
                        print_error "gcompat 安装失败，请手动执行: apk add gcompat libexecinfo"
                        return 1
                    fi
                else
                    return 1
                fi
            fi
        else
            print_error "解压后未找到 sing-box 二进制，请检查"
            return 1
        fi
    fi

    # ---------- 4. 创建或修复服务文件 ----------
    local need_service=0
    if [[ $ALPINE -eq 1 ]]; then
        if [[ ! -f /etc/init.d/sing-box ]]; then
            need_service=1
        else
            # 服务文件必须同时包含日志重定向和降权运行标志，否则重写
            if ! grep -q "/var/log/sing-box.log" /etc/init.d/sing-box \
               || ! grep -q 'command_user' /etc/init.d/sing-box; then
                need_service=1
            fi
        fi
    else
        if [[ ! -f /etc/systemd/system/sing-box.service ]] \
           || ! grep -q 'User=sing-box' /etc/systemd/system/sing-box.service; then
            need_service=1
        fi
    fi

    if [[ $need_service -eq 1 ]]; then
        print_info "创建/更新服务文件..."

        # 创建 sing-box 系统用户和组（用于服务降权运行，避免以 root 运行高攻击面进程）
        # Alpine: BusyBox adduser -S 不创建同名组，须显式 addgroup
        if ! id sing-box &>/dev/null; then
            if [[ $ALPINE -eq 1 ]]; then
                # 先创建组（不存在时），再创建用户并加入该组
                if ! getent group sing-box &>/dev/null; then
                    addgroup -S sing-box 2>/dev/null || addgroup sing-box 2>/dev/null || true
                fi
                adduser -S -H -s /sbin/nologin -G sing-box -D sing-box 2>/dev/null || true
            else
                # useradd -r 默认创建同名组
                useradd -r -s /usr/sbin/nologin -d /nonexistent sing-box 2>/dev/null || true
            fi
        fi
        # 兜底：确保同名组存在（用户已存在但组缺失的修复场景）
        if ! getent group sing-box &>/dev/null; then
            if [[ $ALPINE -eq 1 ]]; then
                addgroup -S sing-box 2>/dev/null || addgroup sing-box 2>/dev/null || true
            else
                groupadd -r sing-box 2>/dev/null || true
            fi
        fi

        # 授予 sing-box 绑定 < 1024 端口的能力（降权运行绑定 443 必须有此 capability）
        # libcap 提供 setcap 命令，上面已安装；此处再兜底确保
        if [[ $ALPINE -eq 1 ]] && ! command -v setcap &>/dev/null; then
            apk add --no-cache libcap >/dev/null 2>&1 || true
        fi
        if command -v setcap &>/dev/null; then
            if ! setcap 'cap_net_bind_service=+ep' "${INSTALL_DIR}/sing-box" 2>/dev/null; then
                print_warning "setcap 失败，降权后 sing-box 将无法绑定 443 等低端口"
                print_warning "请手动安装 libcap 后执行: setcap 'cap_net_bind_service=+ep' ${INSTALL_DIR}/sing-box"
            fi
        else
            print_warning "未找到 setcap 命令，降权后 sing-box 可能无法绑定 443 等低端口"
            print_warning "请安装 libcap: apk add libcap (Alpine) 或 apt install libcap2-bin (Debian)"
        fi

        # 调整关键目录归属，让 sing-box 用户可读写
        chown -R sing-box:sing-box /etc/sing-box 2>/dev/null || true
        chmod 750 /etc/sing-box 2>/dev/null

        # 预创建日志文件（600 防止其他用户读取连接信息）
        mkdir -p /var/log 2>/dev/null
        touch /var/log/sing-box.log
        chown sing-box:sing-box /var/log/sing-box.log 2>/dev/null || true
        chmod 600 /var/log/sing-box.log

        # 预创建 pid 目录（/run 由 root 拥有，sing-box 用户无写权限会导致
        # supervise-daemon 创建 pidfile 失败，服务启动即失败且日志为空）
        mkdir -p /run/sing-box 2>/dev/null
        chown sing-box:sing-box /run/sing-box 2>/dev/null || true
        chmod 750 /run/sing-box 2>/dev/null

        if [[ $ALPINE -eq 1 ]]; then
            cat > /etc/init.d/sing-box << 'EOF'
#!/sbin/openrc-run

name="sing-box"
description="sing-box service"

command="/usr/local/bin/sing-box"
command_args="run -c /etc/sing-box/config.json"
command_user="sing-box:sing-box"
# pidfile 必须放在 sing-box 用户可写目录，否则降权后无法创建 pid，启动即失败
pidfile="/run/sing-box/${name}.pid"
output_log="/var/log/sing-box.log"
error_log="/var/log/sing-box.log"
required_files="/etc/sing-box/config.json"

supervisor="supervise-daemon"
respawn_delay=10
respawn_max=5
respawn_period=60

depend() {
    need net
    after firewall
}

# 启动前确保 pid 目录存在（/run 是 tmpfs，重启后丢失）
start_pre() {
    mkdir -p /run/sing-box
    chown sing-box:sing-box /run/sing-box 2>/dev/null || true
    chmod 750 /run/sing-box 2>/dev/null || true
}
EOF
            chmod +x /etc/init.d/sing-box
            print_success "OpenRC 服务已创建（降权到 sing-box 用户运行）"
        else
            cat > /etc/systemd/system/sing-box.service << 'EOFSVC'
[Unit]
Description=sing-box service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=simple
User=sing-box
Group=sing-box
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=10s
LimitNOFILE=1048576
# systemd 自动管理 /run/sing-box（创建+属主+权限，重启后自动重建）
RuntimeDirectory=sing-box
RuntimeDirectoryMode=0750

# 沙箱加固
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictNamespaces=true
RestrictRealtime=true
RestrictSUIDSGID=true
LockPersonality=true
SystemCallArchitectures=native
# sing-box 需要绑定 443 等低端口（已通过 setcap 授权）
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_BIND_SERVICE CAP_NET_RAW
# 仅允许写 /etc/sing-box 和日志目录（RuntimeDirectory 已自动允许 /run/sing-box）
ReadWritePaths=/etc/sing-box /var/log

[Install]
WantedBy=multi-user.target
EOFSVC
            systemctl daemon-reload
            print_success "systemd 服务已创建（降权到 sing-box 用户 + 沙箱加固）"
        fi
    else
        print_success "服务文件已就绪"
    fi

    # ---------- 5. 开机自启 ----------
    svc_enable

    # ---------- 6. 配置日志清理（首次安装自动设置） ----------
    setup_log_cleanup

    print_success "sing-box 安装/修复完成"
}
# ==================== 证书生成 ====================
gen_cert_for_sni() {
    local sni="$1"
    local node_cert_dir="${CERT_DIR}/${sni}"

    # 安全校验：sni 必须是合法域名，防止路径穿越（../.. 写到任意目录）
    if [[ -z "$sni" ]] || [[ "$sni" == *"/"* ]] || [[ "$sni" == *".."* ]]; then
        print_error "SNI 非法: ${sni}（含路径字符，拒绝生成证书）"
        return 1
    fi

    if ! mkdir -p "${node_cert_dir}"; then
        print_error "创建证书目录失败: ${node_cert_dir}（磁盘满或权限不足）"
        return 1
    fi

    # 生成私钥（umask 077 保证 600）
    if ! (umask 077 && openssl genrsa -out "${node_cert_dir}/private.key" 2048 2>/dev/null); then
        print_error "生成私钥失败: ${sni}"
        return 1
    fi
    if ! openssl req -new -x509 -days 36500 -key "${node_cert_dir}/private.key" -out "${node_cert_dir}/cert.pem" -subj "/C=US/ST=California/L=Cupertino/O=Apple Inc./CN=${sni}" 2>/dev/null; then
        print_error "生成证书失败: ${sni}"
        rm -f "${node_cert_dir}/private.key"
        return 1
    fi

    # 强制权限：private.key 600，cert.pem 644
    chmod 600 "${node_cert_dir}/private.key" 2>/dev/null
    chmod 644 "${node_cert_dir}/cert.pem" 2>/dev/null

    print_success "证书生成完成 (${sni}, 有效期100年)"
}

# ==================== 密钥管理 ====================
gen_keys() {
    print_info "生成 Reality 密钥对..."
    
    if [[ -f "${KEY_FILE}" ]] && [[ -r "${KEY_FILE}" ]]; then
        print_info "从文件加载已保存的密钥..."
        while IFS='=' read -r key value; do
            value="${value#\"}"
            value="${value%\"}"
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            case "$key" in
                REALITY_PRIVATE) REALITY_PRIVATE="$value" ;;
                REALITY_PUBLIC) REALITY_PUBLIC="$value" ;;
                SHORT_ID) SHORT_ID="$value" ;;
            esac
        done < "${KEY_FILE}"
        print_success "密钥加载完成"
        return 0
    fi
    
    KEYS=$(${INSTALL_DIR}/sing-box generate reality-keypair 2>/dev/null)
    REALITY_PRIVATE=$(echo "$KEYS" | grep "PrivateKey" | awk '{print $2}')
    REALITY_PUBLIC=$(echo "$KEYS" | grep "PublicKey" | awk '{print $2}')

    if [[ -z "$REALITY_PRIVATE" || -z "$REALITY_PUBLIC" ]]; then
        print_error "Reality 密钥生成失败"
        print_error "请检查 sing-box 是否正常安装: ${INSTALL_DIR}/sing-box version"
        return 1
    fi
    SHORT_ID=$(openssl rand -hex 8)
    print_info "Reality Short ID 已自动生成: ${SHORT_ID}"
    print_info "如需修改 Short ID，可在添加节点时自定义"
    save_keys_to_file
    print_success "密钥生成完成"
}

save_keys_to_file() {
    mkdir -p "$(dirname "${KEY_FILE}")"
    # 原子写入：临时文件 + mv，避免写入中断损坏密钥文件
    local _tmp
    _tmp=$(mktemp "${KEY_FILE}.XXXXXX.tmp" 2>/dev/null) || { print_error "保存密钥失败（创建临时文件失败）"; return 1; }
    cat > "$_tmp" << EOF
REALITY_PRIVATE="${REALITY_PRIVATE}"
REALITY_PUBLIC="${REALITY_PUBLIC}"
SHORT_ID="${SHORT_ID}"
EOF
    if [[ -s "$_tmp" ]] && mv -f "$_tmp" "${KEY_FILE}"; then
        chmod 600 "${KEY_FILE}"
        print_success "密钥已保存到 ${KEY_FILE}"
        return 0
    else
        rm -f "$_tmp"
        print_error "保存密钥失败（写入失败）"
        return 1
    fi
}


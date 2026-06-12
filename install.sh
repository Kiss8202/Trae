#!/bin/sh
# POSIX sh 引导：检测 bash 是否可用，不可用则安装后用 bash 重新执行
if [ -z "$BASH_VERSION" ]; then
    if ! command -v bash >/dev/null 2>&1; then
        if command -v apk >/dev/null 2>&1; then
            echo "[引导] Alpine 系统，正在安装 bash ..."
            apk add --no-cache bash gcompat libexecinfo >/dev/null 2>&1
        elif command -v apt-get >/dev/null 2>&1; then
            echo "[引导] 正在安装 bash ..."
            apt-get update -qq && apt-get install -y bash >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y bash >/dev/null 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y bash >/dev/null 2>&1
        fi
    fi
    if command -v bash >/dev/null 2>&1; then
        exec bash "$0" "$@"
    fi
    echo "错误: 需要 bash，请先安装 (Alpine: apk add bash; Debian: apt install bash)"
    exit 1
fi

# ==================== 模块加载 ====================
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")")" && pwd)"
MODULES_DIR="${SCRIPT_DIR}/modules"
MODULES_URL="https://raw.githubusercontent.com/Kiss8202/Trae/main/modules"

# 如果模块目录不存在，从 GitHub 下载
if [[ ! -d "$MODULES_DIR" ]]; then
    echo "[引导] 模块目录不存在，正在从 GitHub 下载..."
    mkdir -p "$MODULES_DIR"
    for module in core install links dns relay protocols config menu; do
        echo -n "[引导] 下载模块 ${module}.sh ... "
        if curl -sfL --connect-timeout 10 --max-time 30 "${MODULES_URL}/${module}.sh" -o "${MODULES_DIR}/${module}.sh" 2>/dev/null; then
            echo "完成"
        else
            echo "失败"
            echo "错误: 无法下载模块 ${module}.sh，请检查网络连接"
            exit 1
        fi
    done
fi

# 按顺序加载模块
source "${MODULES_DIR}/core.sh"     || { echo "错误: 无法加载 core.sh"; exit 1; }
source "${MODULES_DIR}/install.sh"  || { echo "错误: 无法加载 install.sh"; exit 1; }
source "${MODULES_DIR}/links.sh"    || { echo "错误: 无法加载 links.sh"; exit 1; }
source "${MODULES_DIR}/dns.sh"      || { echo "错误: 无法加载 dns.sh"; exit 1; }
source "${MODULES_DIR}/relay.sh"    || { echo "错误: 无法加载 relay.sh"; exit 1; }
source "${MODULES_DIR}/protocols.sh"|| { echo "错误: 无法加载 protocols.sh"; exit 1; }
source "${MODULES_DIR}/config.sh"   || { echo "错误: 无法加载 config.sh"; exit 1; }
source "${MODULES_DIR}/menu.sh"     || { echo "错误: 无法加载 menu.sh"; exit 1; }

# 启动主函数
main "$@"

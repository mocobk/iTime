#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# 一键构建 iTime 应用并打包 DMG
set -euo pipefail

# ============================================================
# 配置
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="iTime"
SCHEME="itime"
CONFIGURATION="Release"
DERIVED_DATA_PATH="${PROJECT_DIR}/build"
DIST_DIR="${PROJECT_DIR}/dist"
STAGING_DIR="${DIST_DIR}/staging"

# 默认版本号从 VERSION 文件读取，可通过参数覆盖
VERSION_FILE="${PROJECT_DIR}/VERSION"
if [[ -f "${VERSION_FILE}" ]]; then
    DEFAULT_VERSION="$(cat "${VERSION_FILE}" | tr -d '[:space:]')"
else
    DEFAULT_VERSION="1.0.0"
fi

# ============================================================
# 颜色输出
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ============================================================
# 帮助信息
# ============================================================
usage() {
    cat <<EOF
用法: $(basename "$0") [选项]

一键构建 iTime 应用并打包 DMG

选项:
    -v, --version VERSION   指定版本号 (默认: ${DEFAULT_VERSION})
    -s, --skip-build        跳过构建步骤，仅打包已有 .app
    -c, --clean             构建前清理派生数据
    -h, --help              显示帮助信息

示例:
    $(basename "$0")                     # 使用默认版本号构建
    $(basename "$0") -v 1.2.0           # 指定版本号构建
    $(basename "$0") -c -v 1.2.0        # 清理后构建
    $(basename "$0") -s -v 1.0.0        # 跳过构建，仅打包 DMG

EOF
    exit 0
}

# ============================================================
# 参数解析
# ============================================================
VERSION="${DEFAULT_VERSION}"
SKIP_BUILD=false
CLEAN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            err "未知参数: $1"
            usage
            ;;
    esac
done

DMG_NAME="${APP_NAME}-${VERSION}.dmg"

info "=========================================="
info " iTime 构建脚本"
info " 版本: ${VERSION}"
info "=========================================="

# ============================================================
# 前置检查
# ============================================================
check_prerequisites() {
    info "检查前置条件..."

    if ! command -v xcodebuild &>/dev/null; then
        err "未找到 xcodebuild，请安装 Xcode"
        exit 1
    fi

    if ! command -v hdiutil &>/dev/null; then
        err "未找到 hdiutil，请确认 macOS 环境"
        exit 1
    fi

    ok "前置条件检查通过"
}

# ============================================================
# 清理
# ============================================================
clean_build() {
    if [[ "${CLEAN}" == true ]]; then
        info "清理派生数据..."
        rm -rf "${DERIVED_DATA_PATH}"
        rm -rf "${DIST_DIR}"
        ok "清理完成"
    fi
}

# ============================================================
# 生成 Xcode 项目
# ============================================================
generate_project() {
    info "生成 Xcode 项目..."
    python3 "${PROJECT_DIR}/scripts/generate_xcodeproj.py"
    ok "Xcode 项目生成完成"
}

# ============================================================
# 构建应用
# ============================================================
build_app() {
    if [[ "${SKIP_BUILD}" == true ]]; then
        warn "跳过构建步骤"
        return
    fi

    info "开始构建 ${APP_NAME} (版本: ${VERSION})..."

    xcodebuild \
        -project "${PROJECT_DIR}/itime.xcodeproj" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        SWIFT_VERSION=5.0 \
        SWIFT_STRICT_CONCURRENCY=minimal \
        SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
        GCC_TREAT_WARNINGS_AS_ERRORS=NO \
        MARKETING_VERSION="${VERSION}" \
        CURRENT_PROJECT_VERSION="${VERSION}" \
        clean build

    ok "构建完成"
}

# ============================================================
# 定位并准备 .app
# ============================================================
prepare_app() {
    info "定位构建产物..."

    APP_PATH=$(find "${DERIVED_DATA_PATH}/Build/Products/Release" -maxdepth 2 -name 'itime.app' -print -quit || true)
    if [[ -z "${APP_PATH}" ]]; then
        err "未找到 itime.app，请确认构建是否成功"
        exit 1
    fi

    info "找到 itime.app: ${APP_PATH}"

    # 重命名为 iTime.app
    mkdir -p "${STAGING_DIR}"
    rm -rf "${STAGING_DIR}/${APP_NAME}.app"
    cp -R "${APP_PATH}" "${STAGING_DIR}/${APP_NAME}.app"

    ok "应用已准备: ${STAGING_DIR}/${APP_NAME}.app"
}

# ============================================================
# 创建 DMG
# ============================================================
create_dmg() {
    info "创建 DMG 安装包..."

    mkdir -p "${DIST_DIR}"

    # 创建 Applications 快捷方式
    ln -sf /Applications "${STAGING_DIR}/Applications"

    # 移除旧的 DMG
    rm -f "${DIST_DIR}/${DMG_NAME}"

    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "${STAGING_DIR}" \
        -fs HFS+ \
        -format UDZO \
        -ov \
        "${DIST_DIR}/${DMG_NAME}"

    ok "DMG 创建完成: ${DIST_DIR}/${DMG_NAME}"
    ls -lh "${DIST_DIR}/${DMG_NAME}"
}

# ============================================================
# 输出摘要
# ============================================================
print_summary() {
    echo ""
    info "=========================================="
    info " 构建完成!"
    info "=========================================="
    info " 应用名称: ${APP_NAME}"
    info " 版本号:   ${VERSION}"
    info " DMG 路径: ${DIST_DIR}/${DMG_NAME}"

    DMG_SIZE=$(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1)
    info " DMG 大小: ${DMG_SIZE}"

    echo ""
    info "后续步骤:"
    info "  发布到 GitHub:   ./scripts/release.sh -v ${VERSION}"
    info "  或手动发布:      gh release create v${VERSION} ${DIST_DIR}/${DMG_NAME} --title \"iTime ${VERSION}\""
}

# ============================================================
# 主流程
# ============================================================
main() {
    check_prerequisites
    clean_build
    generate_project
    build_app
    prepare_app
    create_dmg
    print_summary
}

main

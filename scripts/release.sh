#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# 一键发布 iTime 到 GitHub Release
set -euo pipefail

# ============================================================
# 配置
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="iTime"
DIST_DIR="${PROJECT_DIR}/dist"
REPO="mocobk/iTime"

# 默认版本号，从 VERSION 文件读取，可通过参数覆盖
DEFAULT_VERSION="$(tr -d '[:space:]' < "${PROJECT_DIR}/VERSION")"

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

一键构建并发布 iTime 到 GitHub Release

选项:
    -v, --version VERSION   指定版本号 (默认: ${DEFAULT_VERSION})
    -b, --build-only        仅构建，不推送 tag 和发布
    -n, --no-build          跳过构建，使用已有 DMG 文件发布
    -d, --draft             创建为草稿 Release
    -p, --prerelease        标记为预发布版本
    -h, --help              显示帮助信息

示例:
    $(basename "$0")                       # 使用默认版本号构建并发布
    $(basename "$0") -v 1.2.0              # 指定版本号构建并发布
    $(basename "$0") -b -v 1.2.0           # 仅构建，不发布
    $(basename "$0") -n -v 1.0.0           # 使用已有 DMG 发布
    $(basename "$0") -d -v 2.0.0           # 创建草稿 Release
    $(basename "$0") -p -v 2.0.0-beta.1    # 创建预发布版本

EOF
    exit 0
}

# ============================================================
# 参数解析
# ============================================================
VERSION="${DEFAULT_VERSION}"
BUILD_ONLY=false
NO_BUILD=false
DRAFT=false
PRERELEASE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -n|--no-build)
            NO_BUILD=true
            shift
            ;;
        -d|--draft)
            DRAFT=true
            shift
            ;;
        -p|--prerelease)
            PRERELEASE=true
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

TAG="v${VERSION}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

info "=========================================="
info " iTime 发布脚本"
info " 版本: ${VERSION}"
info " Tag:  ${TAG}"
info "=========================================="

# ============================================================
# 前置检查
# ============================================================
check_prerequisites() {
    info "检查前置条件..."

    if ! command -v gh &>/dev/null; then
        err "未找到 gh CLI，请安装: brew install gh"
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        err "gh CLI 未登录，请先运行: gh auth login"
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        err "未找到 git"
        exit 1
    fi

    ok "前置条件检查通过"
}

# ============================================================
# 检查工作区状态
# ============================================================
check_git_status() {
    info "检查 Git 工作区状态..."

    # 切换到项目目录
    cd "${PROJECT_DIR}"

    # 检查是否有未提交的更改
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "存在未提交的更改:"
        git status --short
        echo ""
        read -rp "是否继续发布? (y/N): " confirm
        if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
            info "已取消发布"
            exit 0
        fi
    fi

    # 检查 tag 是否已存在
    if git tag -l "${TAG}" | grep -q "${TAG}"; then
        err "Tag ${TAG} 已存在!"
        err "请使用新的版本号或删除已有 tag: git tag -d ${TAG} && git push origin :${TAG}"
        exit 1
    fi

    ok "Git 状态检查通过"
}

# ============================================================
# 构建应用
# ============================================================
build_app() {
    if [[ "${NO_BUILD}" == true ]]; then
        info "跳过构建步骤"
        if [[ ! -f "${DMG_PATH}" ]]; then
            err "DMG 文件不存在: ${DMG_PATH}"
            err "请先构建或使用 -v 指定正确的版本号"
            exit 1
        fi
        ok "使用已有 DMG: ${DMG_PATH}"
        return
    fi

    info "开始构建..."
    bash "${PROJECT_DIR}/scripts/build.sh" -v "${VERSION}" -c

    if [[ ! -f "${DMG_PATH}" ]]; then
        err "构建完成但未找到 DMG: ${DMG_PATH}"
        exit 1
    fi

    ok "构建完成: ${DMG_PATH}"
}

# ============================================================
# 确认发布
# ============================================================
confirm_release() {
    if [[ "${BUILD_ONLY}" == true ]]; then
        return
    fi

    echo ""
    info "即将发布到 GitHub:"
    info "  仓库:     ${REPO}"
    info "  Tag:      ${TAG}"
    info "  DMG:      ${DMG_NAME}"
    info "  草稿:     ${DRAFT}"
    info "  预发布:   ${PRERELEASE}"

    echo ""
    read -rp "确认发布? (y/N): " confirm
    if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
        info "已取消发布"
        exit 0
    fi
}

# ============================================================
# 推送代码和 Tag
# ============================================================
push_to_github() {
    if [[ "${BUILD_ONLY}" == true ]]; then
        info "仅构建模式，跳过推送"
        return
    fi

    info "推送代码到 GitHub..."

    # 确保当前分支的所有提交已推送
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    git push origin "${current_branch}"

    # 创建并推送 tag
    info "创建并推送 tag ${TAG}..."
    git tag -a "${TAG}" -m "Release ${APP_NAME} ${VERSION}"
    git push origin "${TAG}"

    ok "Tag ${TAG} 已推送"
}

# ============================================================
# 监控 GitHub Actions 工作流
# ============================================================
monitor_workflow() {
    if [[ "${BUILD_ONLY}" == true ]]; then
        return
    fi

    info "等待 Release 工作流触发..."
    sleep 5

    # 查找工作流运行
    local run_id
    run_id=$(gh run list --repo "${REPO}" --workflow="Release DMG" --branch "${TAG}" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)

    if [[ -z "${run_id}" ]]; then
        warn "未找到自动触发的 Release 工作流"
        warn "将使用本地 DMG 文件创建 Release"
        create_release_locally
        return
    fi

    info "Release 工作流已触发 (Run ID: ${run_id})"
    info "监控工作流执行状态..."

    if gh run watch "${run_id}" --repo "${REPO}" --exit-status; then
        ok "Release 工作流执行成功!"
        info "Release 页面: https://github.com/${REPO}/releases/tag/${TAG}"
    else
        err "Release 工作流执行失败"
        err "查看详情: gh run view ${run_id} --repo ${REPO}"
        exit 1
    fi
}

# ============================================================
# 本地创建 Release（当 CI 工作流不可用时回退）
# ============================================================
create_release_locally() {
    info "使用本地 DMG 创建 GitHub Release..."

    local draft_flag=""
    local prerelease_flag=""

    if [[ "${DRAFT}" == true ]]; then
        draft_flag="--draft"
    fi

    if [[ "${PRERELEASE}" == true ]]; then
        prerelease_flag="--prerelease"
    fi

    gh release create "${TAG}" \
        "${DMG_PATH}" \
        --repo "${REPO}" \
        --title "${APP_NAME} ${VERSION}" \
        --generate-notes \
        ${draft_flag} \
        ${prerelease_flag}

    ok "Release 创建成功!"
    info "Release 页面: https://github.com/${REPO}/releases/tag/${TAG}"
}

# ============================================================
# 输出摘要
# ============================================================
print_summary() {
    echo ""
    info "=========================================="
    info " 发布完成!"
    info "=========================================="
    info " 版本号:      ${VERSION}"
    info " Tag:         ${TAG}"
    info " DMG 文件:    ${DMG_PATH}"

    DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
    info " DMG 大小:    ${DMG_SIZE}"

    if [[ "${BUILD_ONLY}" != true ]]; then
        info " Release 页面: https://github.com/${REPO}/releases/tag/${TAG}"
    fi
}

# ============================================================
# 主流程
# ============================================================
main() {
    check_prerequisites
    check_git_status
    build_app
    confirm_release
    push_to_github
    monitor_workflow
    print_summary
}

main

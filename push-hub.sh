#!/usr/bin/env bash
#
# 手動備案：在本機建 linux/amd64 的 image 並推上 Docker Hub。
# 平常不用跑——push 到 main 時 GitHub Actions（.github/workflows/docker.yml）會自動做。
#
#     docker login -u overmindyuan   # 第一次
#     ./push-hub.sh
#
# 在 Apple Silicon 上建 amd64 要靠模擬，會比 Actions 慢很多。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

HUB_USER="${HUB_USER:-overmindyuan}"
AGENT_REPO="${AGENT_REPO:-$HUB_USER/cdy_agent}"
EGRESS_REPO="${EGRESS_REPO:-$HUB_USER/cdy_agent_egress}"
PLATFORM="${PLATFORM:-linux/amd64}"
VERSION="$(cat "$ROOT/VERSION")"   # 寫進 image 的 version label

say() { printf '\033[36m[hub]\033[0m %s\n' "$*"; }
die() { printf '\033[31m[hub]\033[0m %s\n' "$*" >&2; exit 1; }

grep -q 'index.docker.io' "${DOCKER_CONFIG:-$HOME/.docker}/config.json" 2>/dev/null \
  || die "還沒登入 Docker Hub，先跑 docker login -u ${HUB_USER}"

[ -z "$(git status --porcelain)" ] || die '工作目錄有沒 commit 的改動，先 commit 再推（tag 要對得上 commit）。'
sha="sha-$(git rev-parse --short=7 HEAD)"

say "推送 ${EGRESS_REPO}:latest、:${sha}（${PLATFORM}）……"
docker buildx build --platform "$PLATFORM" --push --build-arg VERSION="$VERSION" \
  --tag "${EGRESS_REPO}:latest" --tag "${EGRESS_REPO}:${sha}" "$ROOT/egress"

say "推送 ${AGENT_REPO}:latest、:${sha}（${PLATFORM}）……"
docker buildx build --platform "$PLATFORM" --push --build-arg VERSION="$VERSION" \
  --tag "${AGENT_REPO}:latest" --tag "${AGENT_REPO}:${sha}" "$ROOT"

say '完成。在 Dockhand 用 compose.hub.yaml 重新部署，就會拉到新的 latest。'

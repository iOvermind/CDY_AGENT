#!/usr/bin/env bash
#
# 在本機建出 compose.yaml 要用的兩個 image（本機的 CPU 架構）。
#
#     ./build.sh
#
# 它不啟動任何東西；起停交給 docker compose 或 Dockhand。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

AGENT_IMAGE="${AGENT_IMAGE:-cdy_agent:latest}"
EGRESS_IMAGE="${EGRESS_IMAGE:-cdy_agent_egress:latest}"

say() { printf '\033[36m[build]\033[0m %s\n' "$*"; }
die() { printf '\033[31m[build]\033[0m %s\n' "$*" >&2; exit 1; }

command -v docker >/dev/null 2>&1 || die '找不到 docker。'
docker info >/dev/null 2>&1 || die 'Docker 裝了但連不上 daemon。'

# 資料目錄先建好再交給 Docker，免得被建成 root 擁有的空目錄。
mkdir -p "$ROOT/data/workspace" "$ROOT/data/home" "$ROOT/data/repos"

say "建置 ${EGRESS_IMAGE}……"
docker build --tag "$EGRESS_IMAGE" "$ROOT/egress"

say "建置 ${AGENT_IMAGE}……"
docker build --tag "$AGENT_IMAGE" "$ROOT"

say '完成。docker compose up -d 之後打開 http://127.0.0.1:7681'

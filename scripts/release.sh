#!/usr/bin/env bash
# 進版：依 docs/CHANGELOG.md 的 [Unreleased] 決定新版本號，改 VERSION、轉換 CHANGELOG、commit、打 tag、推送。
#
#     ./scripts/release.sh --dry-run   # 只印出會跳到哪一版、會動哪些檔，什麼都不寫
#     ./scripts/release.sh             # 真的進版並推送
#
# 規則（docs/rules/VERSION_RULES.md §4.1、§4.3）：
#   Removed，或 Changed 裡標 **[破壞性變更]**  → MAJOR（1.0.0 前降為 MINOR）
#   Added、Deprecated、Changed               → MINOR（1.0.0 前降為 MINOR）
#   只有 Fixed、Security                      → PATCH
# 跳哪一位只由類別決定，不能另外指定；也不會自動跳到 1.0.0。
#
# 順序：檢查 → ./tests/run.sh → 改 VERSION 與 CHANGELOG → commit → tag
#       → scripts/build-release.sh <版本號>（有才跑，例如沒有 CI 的專案在本機建 image）→ 推送。
# 推送 tag 後，有 CI 的專案由 GitHub Actions 建 image 並推 :<版本號>。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

dry=0
case "${1:-}" in
    --dry-run) dry=1 ;;
    "") ;;
    *) echo "用法：$0 [--dry-run]" >&2; exit 2 ;;
esac

say() { printf '\033[36m[release]\033[0m %s\n' "$*"; }
die() { printf '\033[31m[release]\033[0m %s\n' "$*" >&2; exit 1; }

log=docs/CHANGELOG.md
[ -f VERSION ] && [ -f "$log" ] || die "找不到 VERSION 或 ${log}。"
cur=$(cat VERSION)
[[ "$cur" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || die "VERSION 不是 x.y.z：$cur"
major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}

# --- 檢查 ---------------------------------------------------------------
branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" = main ] || die "要在 main 上進版，現在在 ${branch}。"
if [ $dry -eq 0 ] && [ -n "$(git status --porcelain)" ]; then
    die "工作區不乾淨，先 commit 或收起來：$(git status --porcelain | head -3 | tr '\n' ' ')"
fi

# [Unreleased] 區塊：從「## [Unreleased]」到下一個「## [」為止
section=$(awk '/^## \[Unreleased\]/{f=1; next} f && /^## \[/{exit} f' "$log")
grep -q '^- ' <<< "$section" || die "[Unreleased] 是空的：沒有面向使用者的變更就只部署、不進版。"

cats=$(grep -o '^### [A-Za-z]*' <<< "$section" | awk '{print $2}' | sort -u | tr '\n' ' ')
breaking=0; grep -q '^- \*\*\[破壞性變更\]\*\*' <<< "$section" && breaking=1
level=patch
case " $cats " in *" Added "*|*" Deprecated "*|*" Changed "*) level=minor ;; esac
case " $cats " in *" Removed "*) level=major ;; esac
[ $breaking -eq 1 ] && level=major
[ "$major" -eq 0 ] && [ $level = major ] && level=minor     # 1.0.0 前降一位

case $level in
    major) new="$((major + 1)).0.0" ;;
    minor) new="$major.$((minor + 1)).0" ;;
    patch) new="$major.$minor.$((patch + 1))" ;;
esac
[ "$new" = 1.0.0 ] && die "進入 1.0.0 是刻意的決定，不由腳本自動跳；請手動進版。"
git rev-parse -q --verify "refs/tags/v$new" >/dev/null && die "tag v$new 已經存在。"
today=$(date +%F)

say "類別：${cats}$( [ $breaking -eq 1 ] && echo '（含破壞性變更）')→ $level"
say "版本：$cur → ${new}（${today}）"
say "會改：VERSION、${log}；會 commit「release: v${new}」、打 tag v${new}、推送 main 與 v$new"
[ -f scripts/build-release.sh ] && say "會跑：scripts/build-release.sh $new"
if [ $dry -eq 1 ]; then say "--dry-run：什麼都沒寫。"; exit 0; fi

# --- 測試 ---------------------------------------------------------------
say "跑測試：./tests/run.sh"
bash tests/run.sh || die "測試沒過，不進版。"

# --- 改檔 ---------------------------------------------------------------
printf '%s\n' "$new" > VERSION
tmp=$(mktemp)
awk -v v="$new" -v d="$today" '
    !done && /^## \[Unreleased\]$/ { print; print ""; print "---"; print ""; print "## [" v "] - " d; done=1; next }
    { print }' "$log" > "$tmp"
mv "$tmp" "$log"
bash tests/test_docs.sh >/dev/null || { git checkout -- VERSION "$log"; die "改完的 VERSION／CHANGELOG 沒通過文件檢查，已還原。"; }

git add VERSION "$log"
git commit -q -m "release: v$new"
git tag -a "v$new" -m "v$new"
say "已 commit 並打 tag v$new"

if [ -f scripts/build-release.sh ]; then
    say "跑 scripts/build-release.sh $new"
    bash scripts/build-release.sh "$new"
fi

# --- 推送 ---------------------------------------------------------------
git push origin main "v$new" || die "推送失敗。本機的 commit 與 tag v$new 都還在，修好後執行：git push origin main v$new"
say "完成：v$new 已推送。"

#!/usr/bin/env bash
# 文件與檔案格式檢查（docs/rules/ 的規範）：./tests/test_docs.sh
#
# 不需要 docker、不需要網路，幾秒內跑完。
# 檢查：
#   ① 所有進版控的文字檔：UTF-8 無 BOM、LF、檔尾剛好一個換行
#   ② 必要文件都在
#   ③ README.md：H1 是「《名稱》(代號)」、緊接一行「> 」定位句、必要章節逐字且依序
#   ④ VERSION 是 semver，docs/CHANGELOG.md 最上面是 [Unreleased]，且有 VERSION 那一版
#   ⑤ 各文件標題用同一個顯示名
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail=0
ok()  { echo "  ✅ $*"; }
bad() { echo "  ❌ $*"; fail=1; }

# 專案代號＝repo 名：先看 origin 的網址，沒有 remote 才用資料夾名
code=$(basename "$(git remote get-url origin 2>/dev/null || git rev-parse --show-toplevel 2>/dev/null || pwd)" .git)

echo "① 文字檔格式"
n=0
while IFS= read -r -d '' f; do
    [ -f "$f" ] || continue
    grep -Iq . "$f" 2>/dev/null || continue          # 二進位或空檔跳過
    n=$((n + 1))
    if [ "$(head -c 3 "$f" | od -An -tx1 | tr -d ' \n')" = efbbbf ]; then bad "${f}：有 BOM"; fi
    if grep -q $'\r' "$f"; then bad "${f}：有 CRLF（必須是 LF）"; fi
    if [ "$(tail -c 1 "$f" | od -An -tx1 | tr -d ' \n')" != 0a ]; then
        bad "${f}：檔尾沒有換行"
    elif [ "$(tail -c 2 "$f" | od -An -tx1 | tr -d ' \n')" = 0a0a ]; then
        bad "${f}：檔尾多了空行（只能一個換行）"
    fi
done < <(git ls-files -z --cached --others --exclude-standard)
[ $fail -eq 0 ] && ok "$n 個文字檔都是 UTF-8 無 BOM、LF、檔尾一個換行"

echo "② 必要文件"
for f in README.md CLAUDE.md LICENSE VERSION \
         docs/PRODUCT.md docs/DEVELOPER.md docs/CHANGELOG.md docs/DEPLOY.md \
         docs/agents/issue-tracker.md docs/agents/triage-labels.md docs/agents/domain.md \
         docs/rules/README_RULES.md docs/rules/templates/README.template.md; do
    [ -s "$f" ] && ok "$f" || bad "缺少 $f"
done

echo "③ README.md"
h1=$(grep -m1 '^# ' README.md 2>/dev/null)
if [[ "$h1" =~ ^#\ 《[^》]+》\(${code}\)$ ]]; then ok "H1：${h1#\# }"; else bad "H1 必須是「# 《名稱》(${code})」，現在是「${h1}」"; fi
display=${h1#\# }
tagline=$(awk '!f && /^# /{f=1; next} f && NF{print; exit}' README.md)
markup='[`*[]'                                         # 程式碼、粗體、連結
if [[ "$tagline" == "> "* ]] && ! [[ "$tagline" =~ $markup ]]; then ok "定位句是純文字引述行"; else bad "H1 下一個非空行必須是純文字的「> 」定位句，現在是「${tagline}」"; fi
want=("這是什麼" "取得與安裝" "快速開始" "常見問題" "授權" "開發者")
got=$(grep '^## ' README.md | sed 's/^## //')
i=0
while IFS= read -r h; do
    [ $i -lt ${#want[@]} ] && [ "$h" = "${want[$i]}" ] && i=$((i + 1))
done <<< "$got"
[ $i -eq ${#want[@]} ] && ok "必要章節齊全且依序" || bad "必要章節缺「${want[$i]:-}」或順序不對（應為：${want[*]}）"

echo "④ 版本號"
ver=$(cat VERSION 2>/dev/null)
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && ok "VERSION＝$ver" || bad "VERSION 必須是 x.y.z（不帶 v），現在是「${ver}」"
first=$(grep -m1 '^## ' docs/CHANGELOG.md 2>/dev/null)
[ "$first" = "## [Unreleased]" ] && ok "CHANGELOG 最上面是 [Unreleased]" || bad "CHANGELOG 第一個 H2 必須是「## [Unreleased]」"
grep -Eq "^## \[${ver//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" docs/CHANGELOG.md 2>/dev/null \
    && ok "CHANGELOG 有 [$ver] 版本區塊" || bad "CHANGELOG 找不到「## [$ver] - YYYY-MM-DD」"

echo "⑤ 顯示名一致"
for pair in "docs/DEVELOPER.md:# ${display} 開發者文件" "docs/CHANGELOG.md:# ${display} 變更紀錄" "CLAUDE.md:# ${display}"; do
    f=${pair%%:*}; want_h1=${pair#*:}
    [ "$(grep -m1 '^# ' "$f" 2>/dev/null)" = "$want_h1" ] && ok "$f" || bad "$f 的 H1 必須是「${want_h1}」"
done
grep -q "${display}" docs/PRODUCT.md 2>/dev/null && ok "docs/PRODUCT.md 提到 ${display}" || bad "docs/PRODUCT.md 的 Product Purpose 沒有寫顯示名"

echo
[ $fail -eq 0 ] && echo "文件檢查全部通過" || echo "文件檢查有失敗"
exit $fail

#!/usr/bin/env bash
# 本專案唯一的測試入口：./tests/run.sh（CI 與 scripts/release.sh 都跑這支）
#
# 本專案沒有功能測試（容器行為靠本機 docker compose 實際操作驗證，見 docs/DEVELOPER.md §6）。
# 這裡做得到的是：
#   ① 文件與檔案格式（tests/test_docs.sh）
#   ② 所有 shell／Python 腳本的語法
#   ③ 兩份 compose 檔能被 docker compose 解析（沒有 docker 就略過，會印「略過」）
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail=0
ok()   { echo "  ✅ $*"; }
bad()  { echo "  ❌ $*"; fail=1; }
skip() { echo "  ⏭️  略過：$*"; }

bash tests/test_docs.sh || fail=1

echo
echo "② 腳本語法"
for f in build.sh push-hub.sh scripts/*.sh tests/*.sh rootfs/usr/local/bin/*; do
    [ -f "$f" ] || continue
    case "$(head -1 "$f")" in
        *python3*) python3 -c 'import sys; compile(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1], "exec")' "$f" \
                       && ok "${f}（python）" || bad "${f}：Python 語法錯誤" ;;
        *bash*)    bash -n "$f" && ok "${f}（bash）" || bad "${f}：bash 語法錯誤" ;;
        *sh*)      sh -n "$f"   && ok "${f}（sh）"   || bad "${f}：sh 語法錯誤" ;;
    esac
done

echo
echo "③ compose 檔"
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    # 正式版要的兩個變數在這裡給假值，只驗語法與結構
    TUNNEL_TOKEN=x ADMIN_PASSWORD_HASH=x docker compose -f compose.yaml config -q \
        && ok compose.yaml || bad "compose.yaml 解析失敗"
    TUNNEL_TOKEN=x ADMIN_PASSWORD_HASH=x docker compose -f compose.hub.yaml config -q \
        && ok compose.hub.yaml || bad "compose.hub.yaml 解析失敗"
else
    skip "找不到 docker compose，沒有驗 compose.yaml、compose.hub.yaml"
fi

echo
[ $fail -eq 0 ] && echo "全部通過" || echo "有失敗"
exit $fail

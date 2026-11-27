# 《代理終端機》(CDY_AGENT) 變更紀錄

本檔案記錄本專案所有值得使用者知道的變更。

格式依 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本號依語意化版本
（見 `rules/VERSION_RULES.md`）。日期格式為 `YYYY-MM-DD`。

## [Unreleased]

### Added (新增)
- rea 的 Ghidra 分析會自動存檔（checkpoint）：分析結果與改名、註解存在 `~/.cache/rea/ghidra-checkpoints`，重開同一個檔直接接續，不必重新分析。要用分析種子（`REA_GHIDRA_SEED_FILE`）或指定語言時，得先取消 `REA_GHIDRA_CHECKPOINT_DIR`。

---

## [1.1.0] - 2026-11-28

### Added (新增)
- 預裝 Claude plugin `ui-ux-pro-max`（UI/UX 設計知識庫：風格、配色、字型、UX 準則與各框架寫法，另含品牌、簡報、橫幅等設計技能）。
- 預裝 Claude plugin `rea`（逆向工程：分析已發佈的執行檔、套件、Electron／網頁應用與韌體），連同它的 rea MCP。
- 預裝 Ghidra 12.2 與 JDK 25，讓 rea 可以反編譯原生程式（image 因此大約多 1 GB 以上）。
- 說明頁加上這兩個 plugin 的介紹與技能中文說明，MCP 區塊也列出 plugin 自帶的 MCP。

---

## [1.0.0] - 2026-11-23

首次建立變更紀錄：本版列出目前已提供的主要功能。

### Added (新增)
- 用瀏覽器輸入工號，就能在自己的 tmux session 裡使用 Claude Code、Gemini CLI、Codex CLI。
- 每個工號有自己的 session 選單與 `/workspace/<工號>`，選單裡可換工號。
- admin 入口 `/admin`：要密碼，看得到並可附接所有工號的 session，預設目錄是 `/repos`。
- `agent-git-setup` 讓每個工號設定自己的 git 身分與 SSH 金鑰。
- 選單按 `?` 或執行 `agent-help` 開啟說明頁，列出快捷鍵、已安裝的 plugin 與技能（附中文說明與觸發方式）、語言工具與網路限制。
- 容器啟動時自動補齊 Claude marketplace、plugin 與 codegraph MCP，不覆蓋已登入的憑證。
- 對外連線一律經 egress proxy，擋掉私網段，只放行 HTTP／HTTPS 與 CONNECT 到 22、443。
- image 由 GitHub Actions 建好推上 Docker Hub，每週一自動重建跟上新版的 Agent CLI。

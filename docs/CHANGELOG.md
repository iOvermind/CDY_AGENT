# 《代理終端機》(CDY_AGENT) 變更紀錄

本檔案記錄本專案所有值得使用者知道的變更。

格式依 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本號依語意化版本
（見 `rules/VERSION_RULES.md`）。日期格式為 `YYYY-MM-DD`。

## [Unreleased]

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

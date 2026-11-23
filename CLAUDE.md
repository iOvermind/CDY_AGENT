# 《代理終端機》(CDY_AGENT)

給同仁用的 AI Agent 終端機容器（ttyd + 工號 tmux 選單）。部署型服務，image 推上 Docker Hub。

- 文件：怎麼用見 `README.md`；改程式前讀 `docs/DEVELOPER.md`（架構、測試、建置、版本號、陷阱）；部署與 Cloudflare 設定見 `docs/DEPLOY.md`；產品事實見 `docs/PRODUCT.md`；每一版變了什麼見 `docs/CHANGELOG.md`；文件與發佈規範見 `docs/rules/`。
- 根目錄只放 `README.md`、`CLAUDE.md`、`LICENSE`，其餘文件一律放 `docs/`。`docs/rules/` 是 DEV_TEMPLATE 的副本，不在這裡改。
- **這是公開 repo**：文件、compose、註解只寫佔位符（`<網域>`、`/path/to/...`、`USER1`、`ADMIN1`），不寫真實網域、IP、工號、權杖。
- 測試：`bash tests/run.sh`（文件格式、腳本語法、compose 解析）。改完必跑；面向使用者的變更同時補 `docs/CHANGELOG.md` 的 `[Unreleased]`。
- 進版：`./scripts/release.sh --dry-run` 先看，再 `./scripts/release.sh`。版本號單一來源是 `VERSION`，不要手改其他地方。
- 文件一律繁體中文；UTF-8 無 BOM、LF、檔尾一個換行。

## Agent skills

### Issue tracker

待辦放在 GitHub Issues（iOvermind/CDY_AGENT，用 `gh`）。See `docs/agents/issue-tracker.md`.

### Triage labels

使用預設的五個標籤（needs-triage、needs-info、ready-for-agent、ready-for-human、wontfix）。See `docs/agents/triage-labels.md`.

### Domain docs

Single-context：名詞表在 `docs/GLOSSARY.md`，決議在 `docs/adr/`（目前都還沒有，由 `domain-modeling` 在需要時建立）。See `docs/agents/domain.md`.

## 向使用者提問

- 需要使用者做決定時，一律用可點選的選項提問（AskUserQuestion 工具），把推薦的選項放第一個並標「（推薦）」。一次最多四題，題目多就分輪問。

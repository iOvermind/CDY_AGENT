# 《代理終端機》(CDY_AGENT) 開發者文件

> 這份文件給**要修改這個專案的人與 agent**。使用說明請看 [README.md](../README.md)。

---

## 1. 技術棧與系統需求

| 項目 | 版本 | 用途 |
| :--- | :--- | :--- |
| Docker Engine | 23 以上（預設用 BuildKit；`COPY --chmod` 需要） | 建 image、本機跑 |
| Docker Compose | v2 | 本機驗證（`compose.yaml`）、正式部署（`compose.hub.yaml`） |
| Bash | 4 以上（容器內 Debian bookworm 的 bash） | 入口、登入、`agent-seed`、`agent-git-setup` |
| Python | 3（容器內 Debian bookworm 的 python3） | `agent-selector`、`agent-help` |
| 基底 image | `node:24-bookworm-slim`、egress 用 `debian:bookworm-slim` | — |
| ttyd | 1.7.7（`Dockerfile` 的 `ARG TTYD_VERSION`） | 瀏覽器終端機 |
| Go | 1.27.4（`Dockerfile` 的 `ARG GO_VERSION`） | 預裝給同仁用的工具鏈 |

**作業系統限制**：正式 image 只建 linux/amd64。在 Apple Silicon 上 `./build.sh` 建的是本機架構（arm64），只能驗證「建得起來、跑得動」；`./push-hub.sh` 建 amd64 要靠模擬，很慢。

---

## 2. 環境建置

1. 取得原始碼
   ```bash
   git clone git@github.com:iOvermind/CDY_AGENT.git
   cd CDY_AGENT
   ```
   完成後應看到 `Dockerfile`、`compose.yaml`、`rootfs/`。

2. 確認 Docker 可用
   ```bash
   docker info --format '{{.ServerVersion}}'
   docker compose version
   ```
   完成後應看到版本號，沒有 `Cannot connect to the Docker daemon`。

3. 建本機 image
   ```bash
   ./build.sh
   ```
   完成後應看到 `[build] 完成。`，`docker images` 有 `cdy_agent:latest` 與 `cdy_agent_egress:latest`，並建好 `./data/`（已在 `.gitignore`）。

---

## 3. 日常開發

**啟動**

```bash
docker compose up -d
open http://127.0.0.1:7681
```

本機版多 `peek`、`peek-admin` 兩個 socat 容器，把 `127.0.0.1:7681`（同仁）與 `127.0.0.1:7682/admin`（admin，工號 `ADMIN1`、密碼 `test`）轉進 internal 網路；正式的 `compose.hub.yaml` 沒有它們。要連 Cloudflare Tunnel 一起測：在 `.env` 填 `TUNNEL_TOKEN`，再 `docker compose --profile tunnel up -d`。

**修改後如何反映**：`rootfs/`、`plugins.txt`、`claude-settings.json`、`skills-zh.json` 都是 `COPY` 進 image 的，改完要 `./build.sh` 再 `docker compose up -d` 重建容器。`egress/squid.conf` 同樣烤在 egress image 裡。

**除錯**：

- 容器啟動 log：`docker compose logs agent`（`[entrypoint] ...`）。
- `agent-seed` 的 log：容器裡的 `~/.cache/agent-seed.log`（本機在 `./data/home/.cache/agent-seed.log`）。
- 對外連線：`docker compose logs egress`，每筆連線一行。
- 進容器：`docker compose exec agent bash`。

---

## 4. 目錄結構

```text
CDY_AGENT/
├─ Dockerfile                 agent image（同仁與 admin 共用，用 AGENT_ROLE 區分）
├─ egress/                    egress proxy（squid）image 與黑名單設定
├─ rootfs/
│  ├─ usr/local/bin/          容器裡的指令：入口、登入、選單、說明頁、git 身分、補齊 plugin
│  └─ etc/                    tmux 設定、SSH 經 proxy 的設定
├─ plugins.txt                容器啟動時補齊的 Claude marketplace 與 plugin
├─ claude-settings.json       ~/.claude/settings.json 的預設值（不存在時才寫入）
├─ skills-zh.json             說明頁的技能中文對照
├─ compose.yaml               本機驗證
├─ compose.hub.yaml           正式部署（Dockhand）
├─ build.sh                   本機建兩個 image
├─ push-hub.sh                手動備案：建 amd64 並推 Docker Hub
├─ VERSION                    版本號的單一來源
├─ scripts/release.sh         進版腳本
├─ tests/                     run.sh（唯一測試入口）、test_docs.sh（文件格式）
├─ .github/workflows/         CI：測試、建 image、推 Docker Hub
├─ docs/
│  ├─ PRODUCT.md              為誰做、為什麼做
│  ├─ DEVELOPER.md            怎麼改它（本文件）
│  ├─ CHANGELOG.md            每一版變了什麼
│  ├─ DEPLOY.md               正式部署、Cloudflare、更新與回滾
│  ├─ agents/                 agent 的工作設定（issue tracker、triage 標籤、領域文件位置）
│  └─ rules/                  文件與發佈規範的副本（DEV_TEMPLATE）
├─ README.md                  怎麼用它
├─ CLAUDE.md                  agent 的入口
└─ LICENSE                    授權全文
```

---

## 5. 架構與關鍵設計決策

### 模組職責

| 模組 | 職責 | 介面（入口檔） | 接縫／轉接器 | 依賴 |
| :--- | :--- | :--- | :--- | :--- |
| 入口 | 補齊家目錄、建立工號 workspace、背景跑 `agent-seed`、啟動 ttyd | `agent-entrypoint`；環境變數 `AGENT_ROLE`、`AGENT_USERS`、`AGENT_ADMINS`、`TTYD_BASE_PATH`、`TTYD_CREDENTIAL` | 無 | ttyd、登入 |
| 登入 | 輸入工號、admin 驗密碼，交給選單 | `agent-login`（ttyd 執行的指令）；不合法或不在清單的工號一律拒絕 | 無 | 選單 |
| 選單 | 工號專屬的 tmux socket 與 session 選單；admin 版列出所有工號 | `agent-selector [--admin] <工號>`；設定 session 的 `AGENT_USER` | tmux socket 目錄（agent 與 admin 容器共用同一個 host 目錄） | tmux、說明頁 |
| 說明頁 | 列出快捷鍵、已安裝的 plugin 與技能、工具、網路限制 | `agent-help` | 讀 `~/.claude/plugins` 與 `/opt/agent/skills-zh.json` | 無 |
| git 身分 | 每個工號自己的 gitconfig 與 SSH 金鑰 | `agent-git-setup`（設定）、`agent-git-ssh`（`GIT_SSH_COMMAND`） | 依 `AGENT_USER` 挑 `/workspace/<工號>/.agent/ssh/id_ed25519`，沒有就退回一般 ssh | ssh、egress |
| 補齊 plugin | 依 `plugins.txt` 補齊 marketplace、plugin、codegraph MCP，只補沒有的 | `agent-seed` | 無 | claude CLI、egress |
| egress | 所有對外連線的唯一出口，擋私網段 | HTTP proxy `egress:3128` | `egress/squid.conf` | 無 |

依賴方向：入口 → 登入 → 選單 → 說明頁；agent 容器的一切對外連線都經 egress，egress 不依賴 agent。

### 模組介面

| 介面 | 提供者 | 使用者 | 說明 |
| :--- | :--- | :--- | :--- |
| 環境變數 `AGENT_ROLE`、`AGENT_USERS`、`AGENT_ADMINS`、`AGENT_ADMIN_PASSWORD_HASH`、`TTYD_BASE_PATH`、`TTYD_CREDENTIAL` | compose | 入口、登入 | 部署設定的全部契約，說明見 `DEPLOY.md` §3 |
| `AGENT_USER` | 選單 | git 身分、說明頁 | tmux session 的工號 |
| `plugins.txt` 的格式 | 本 repo | `agent-seed` | 一行：`marketplace名稱  owner/repo  [plugin ...]`，`#` 開頭是註解 |
| `skills-zh.json` | 本 repo | 說明頁 | key 是 `plugin名稱/技能名稱`，value 是中文說明 |
| `http://agent:7681`、`http://admin:7681` | ttyd | cloudflared | 健康檢查也打這裡 |

### 關鍵決策

#### agent 與 admin 拆兩個容器

- **決定**：同一個 image 跑兩個容器，`/repos` 只掛在 admin 容器。
- **理由**：容器裡所有人都是同一個 Linux 帳號 `dev`，同一個容器擋不住誰 `cd` 到哪；不掛載是唯一可靠的隔離。
- **代價**：多一個容器的資源；兩個容器要共用家目錄與 tmux socket 目錄，admin 才附接得到同仁的 session。

#### 工號是軟區分，所有人共用一個 Linux 帳號

- **決定**：不建多個 Linux 帳號，工號只決定 tmux socket 與 workspace。
- **理由**：三個 Agent 只需登入一次、所有人共用；使用者是彼此信任的同事，真正的門是 Cloudflare Access。
- **代價**：看得到彼此的 workspace、金鑰與 admin 密碼雜湊；不能當權限控管。

#### 對外一律經 egress proxy，用黑名單擋私網段

- **決定**：agent 只接沒有對外路由的 `internal` 網路，出網只能經 squid。
- **理由**：不用動主機防火牆，就能保證容器連不到區域網路上的設備與主機本身。
- **代價**：proxy 以外的協定（資料庫、自訂埠 TCP、ping）不通；不理會 proxy 變數的程式連不出去。

#### Agent CLI 不鎖版本，每週重建

- **決定**：`Dockerfile` 安裝三個 Agent CLI 時不指定版本，CI 每週一重建。
- **理由**：Agent CLI 更新很快，跟上新版的價值大於可重現性。
- **代價**：同一個版本號的 image 在不同週建出來，裡面的 CLI 版本可能不同；回滾用 `sha-xxxxxxx`。

#### 工具鏈裝在 /opt、/usr/local，不放家目錄

- **決定**：所有工具鏈與全域 npm 套件裝在 `/opt`、`/usr/local`。
- **理由**：正式環境 `/home/dev` 是 host path，image 裡放進家目錄的東西會被掛載蓋掉。
- **代價**：同仁自己 `npm -g`、`cargo install` 的東西放在家目錄的快取，與 image 的工具分開管理。

---

## 6. 測試

```bash
bash tests/run.sh
```

| 分類 | 涵蓋範圍 | 備註 |
| :--- | :--- | :--- |
| 文件 | `tests/test_docs.sh`：文字檔 UTF-8 無 BOM、LF、檔尾一個換行；必要文件存在；README 的 H1、定位句、必要章節；`VERSION` 與 `CHANGELOG.md` 一致；各文件顯示名一致 | 不需要 docker |
| 語法 | 所有 shell 腳本 `bash -n`／`sh -n`，Python 腳本編譯檢查（不寫 `__pycache__`） | — |
| 設定 | `compose.yaml`、`compose.hub.yaml` 能被 `docker compose config` 解析 | 沒有 docker 時略過 |

**本專案沒有功能測試。** 登入、選單、admin 附接、git 身分、egress 擋私網段這些行為，目前靠本機 `docker compose up -d` 後實際操作驗證。

**已約定的接縫**

| 接縫 | 抓得到 | 抓不到 |
| :--- | :--- | :--- |
| `tests/run.sh` 整體 | 文件格式、腳本語法錯誤、compose 結構錯誤 | 任何執行期行為 |
| 建 image（`./build.sh`） | Dockerfile 壞掉、上游套件裝不起來 | amd64 專屬的問題（本機是 arm64 時） |

要加功能測試時，接縫建議是「起一組 compose，從 `peek` 的埠送輸入」或直接對 `agent-login`／`agent-selector` 餵 stdin；新增前先改這張表。修 bug 先寫一個重現它的失敗測試（見 `rules/DEVELOPER_RULES.md` §4.11）。

**會被略過的測試**：找不到 `docker compose` 時，compose 檢查印「⏭️ 略過」而不是「❌」，整體仍算通過。CI 的 ubuntu runner 有 docker，不會略過。

---

## 7. 建置與產物

**建置**

```bash
./build.sh        # 本機架構，給 compose.yaml 用
./push-hub.sh     # 手動備案：linux/amd64，推 Docker Hub
```

平常不用手動推：push 到 `main` 或推 `v*` tag 時，GitHub Actions（`.github/workflows/docker.yml`）先跑 `bash tests/run.sh`，再建 linux/amd64 推上 Docker Hub。需要的 Secrets：`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`。只改 `*.md`、`LICENSE`、`docs/` 不會觸發 main 的建置；tag 一律觸發。

**產物**

| 產物 | 用途 |
| :--- | :--- |
| `overmindyuan/cdy_agent:<版本號>` | agent image（同仁與 admin 共用）；另有 `latest`、`sha-xxxxxxx` |
| `overmindyuan/cdy_agent_egress:<版本號>` | egress proxy image；另有 `latest`、`sha-xxxxxxx` |

沒有 GitHub Release 頁面與下載附件（部署型，見 `rules/RELEASE_RULES.md` §3.4）。

### 版本號

**單一來源**：`VERSION` 的內容（一行 `x.y.z`）

| 位置 | 欄位 | 方式 |
| :--- | :--- | :--- |
| `VERSION` | 全文 | 手動或進版腳本（單一來源） |
| `docs/CHANGELOG.md` | 版本標題 | 進版腳本 |
| git tag | `v<版本號>` | 進版腳本 |
| `Dockerfile`、`egress/Dockerfile` | `ARG VERSION` → `LABEL org.opencontainers.image.version` | 自動（CI 與 `build.sh`、`push-hub.sh` 從 `VERSION` 傳入；預設 `dev`） |
| Docker Hub 的 image tag | `:<版本號>` | 自動（CI 在推 `v*` tag 時加） |

標為「自動」的位置不得手動修改。發佈前依 `rules/VERSION_RULES.md` §7 逐項核對。

**進版腳本**：`scripts/release.sh`

```bash
./scripts/release.sh --dry-run    # 印出會跳到哪一版、會動哪些檔，什麼都不寫
./scripts/release.sh              # 真的進版
```

它依 `docs/CHANGELOG.md` 的 `[Unreleased]` 裡出現的類別決定跳哪一位（`Removed` 或 **[破壞性變更]** → MAJOR；`Added`、`Changed`、`Deprecated` → MINOR；只有 `Fixed`、`Security` → PATCH），不能另外指定。流程：要在 `main`、工作區乾淨、`[Unreleased]` 有內容 → 跑 `./tests/run.sh` → 改 `VERSION`、把 `[Unreleased]` 轉成 `## [x.y.z] - 日期` → commit `release: vX.Y.Z`、打 annotated tag → `git push origin main vX.Y.Z`。推上去後 CI 建 image 並推 `:X.Y.Z`。`[Unreleased]` 是空的就不進版，只部署。

---

## 8. 分支、commit 與 PR 慣例

- **主分支**：`main`，push 就會觸發 CI 建 image 並更新 `latest`。
- **開分支**：小改直接在 `main`；較大的改動從 `main` 開功能分支，合併後刪除。
- **commit 訊息**：繁體中文，一句話講使用者看得到的變化（例：「選單加入說明頁（? 鍵 / agent-help）」）；進版由腳本寫 `release: vX.Y.Z`。

### 舊實作的保留

目前無。舊實作以分支保留、不刪除；該分支不再接受新功能。

---

## 9. 安全與敏感資料

### 9.1 機密不進版控

| 項目 | 排除方式 | 本機該放哪 |
| :--- | :--- | :--- |
| `TUNNEL_TOKEN`、`ADMIN_PASSWORD_HASH` | `.gitignore` 的 `.env`；正式環境填在 Dockhand 的變數 | 本機 `.env`；正式環境 Dockhand |
| Agent 登入憑證、SSH 金鑰 | `.gitignore` 的 `data/`；正式環境在 host path | 本機 `./data/home`、`./data/workspace/<工號>/.agent/`；正式環境 `/path/to/home`、`/path/to/admin-ssh` |
| Docker Hub 權杖 | 只放在 GitHub Actions Secrets | `DOCKERHUB_TOKEN` |

`compose.yaml` 裡的 `AGENT_ADMIN_PASSWORD_HASH` 是本機測試用密碼 `test` 的雜湊，刻意進版控，不是機密。這是公開 repo：真實網域、IP、工號都不得寫進版控。

### 9.2 權限最小化

| 要求的權限 | 為什麼需要 |
| :--- | :--- |
| 容器以 UID/GID 3000（`dev`）執行 | 對應 host 資料目錄的擁有者 |
| 讀寫 `/workspace`、`/home/dev`、tmux socket 目錄 | 程式碼、登入憑證、session |
| 讀寫 `/repos`（只有 admin 容器） | admin 管理所有 repo |
| 經 egress 對外連 HTTP／HTTPS、CONNECT 22 與 443 | Agent 呼叫 API、套件下載、git |

**刻意不要的權限**：`cap_drop: ALL`、`no-new-privileges`；不接對外網路、不 publish 任何埠（只 `expose`）；egress 擋掉私網段，所以連不到區域網路與主機本身；同仁的容器沒有 `/repos`，也看不到 admin 的 SSH 金鑰。

### 9.3 依賴來源與鎖檔

- 鎖檔：無。Agent CLI 與 npm 全域套件刻意不鎖版本（見 §5），ttyd 與 Go 以 `ARG` 鎖版本，uv 取 `ghcr.io/astral-sh/uv:latest`。
- 安裝指令：在 `Dockerfile` 裡用 `npm install -g`、官方安裝腳本與 apt；不在 host 上安裝任何東西。
- Claude plugin 的來源固定寫在 `plugins.txt`（GitHub `owner/repo`）。

### 9.4 破壞性操作的保護

| 操作 | 影響的資料 | 可回復機制 |
| :--- | :--- | :--- |
| Agent 在 workspace 裡改檔、刪檔 | `/workspace/<工號>`、`/repos` | 沒有自動備份；唯一的保護是勤 commit／push |
| 重建容器 | 容器內非掛載路徑的檔案 | 掛載的 host path 不受影響；放在 `/home/dev` 以外、未掛載的東西會消失 |
| `agent-seed` 補 plugin | `~/.claude/plugins` | 只補沒有的，不覆蓋已登入的憑證，同仁自己裝的不動 |

---

## 10. 已知陷阱

#### macOS 上產生 admin 密碼雜湊失敗

- **症狀**：`openssl passwd -6` 出現 `passwd: Unknown option or message digest: 6`。
- **原因**：macOS 內建的是 LibreSSL，不支援 `-6`（SHA-512 crypt）。
- **處置**：在部署主機（Linux）上跑 `openssl passwd -6 | base64 -w0; echo`。

#### tmux 拒絕啟動，選單進不去

- **症狀**：entrypoint log 出現 `警告：無法把 /tmp/tmux-3000 設成 700，tmux 可能拒絕啟動`。
- **原因**：tmux 要求 socket 目錄只有自己能讀寫；host 目錄若不是 `3000:3000` 擁有，容器改不了權限。
- **處置**：在 host 上 `sudo install -d -o 3000 -g 3000 -m 700 /path/to/tmux`。

#### 放進 /home/dev 的工具在正式環境不見了

- **症狀**：本機 image 裡有的指令，正式環境出現 `command not found`。
- **原因**：正式環境 `/home/dev` 是 host path，會蓋掉 image 裡的家目錄。
- **處置**：工具一律裝在 `/opt` 或 `/usr/local`；家目錄的預設檔放 `/etc/skel`，由 `agent-entrypoint` 補回（已存在的不動）。

#### 在 NAS 掛載的資料夾裡 git status 一堆權限變更

- **症狀**：`git status` 列出所有檔案，`git diff` 只有 `old mode 100644` / `new mode 100755`。
- **原因**：SMB 掛載把所有檔案回報成可執行。
- **處置**：`git config core.fileMode false`。新加的可執行腳本要 `git add --chmod=+x <檔>`，並用 `git ls-files -s` 確認是 `100755`。

---

## 相關文件

- 使用說明：[README.md](../README.md)
- 產品事實：[PRODUCT.md](PRODUCT.md)
- 部署：[DEPLOY.md](DEPLOY.md)
- 變更紀錄：[CHANGELOG.md](CHANGELOG.md)
- 文件與發佈規範：[rules/](rules/)

# 《代理終端機》(CDY_AGENT)

> 提供同仁使用 AI Agent 開發的環境。用瀏覽器輸入工號，就能在自己的工作階段裡使用 Claude Code、Gemini CLI、Codex CLI。

---

## 這是什麼

同仁想用 AI 程式助手，卻不想每個人各自在電腦上裝工具、登入、管訂閱。這個容器把三個 Agent CLI 與常用的語言工具鏈裝在一起，部署在一台主機上；同仁打開瀏覽器、通過 Cloudflare Access、輸入工號，就進到自己專屬的 tmux 選單，程式碼放在 `/workspace/<工號>`。

```text
瀏覽器 → Cloudflare Access → cloudflared → http://agent:7681（ttyd）
  → 輸入工號（只接受 AGENT_USERS 裡的值）
  → 該工號專屬的 tmux socket（sock_<工號>）與 session 選單
  → 新 session 的目錄：/workspace/<工號>
```

**主要功能**

- 用瀏覽器就能用 Claude Code、Gemini CLI、Codex CLI，三個 Agent 由一個人登入一次，所有人共用。
- 每個工號有自己的 tmux session 選單與 workspace，彼此不會搶同一個畫面。
- 每個工號可以設定自己的 git 身分與 SSH 金鑰，用自己的 GitHub 帳號 commit 與 push。
- admin 入口（同網域的 `/admin`）看得到所有工號的 session，並能管理放所有 repo 的 `/repos`。
- 對外連線一律經過 egress proxy，連不到區域網路上的設備與主機本身。
- 選單裡按 `?` 就有說明頁，列出快捷鍵、已安裝的 plugin 與技能（附中文說明）、語言工具與網路限制。

**裝了什麼**

| 類別 | 內容 |
| :--- | :--- |
| Agent CLI | Claude Code、Gemini CLI、Codex CLI（不鎖版本，每次建 image 拿最新） |
| 語言工具鏈 | Node 24、Rust stable（rust-analyzer、clippy、rustfmt）、Go、uv（Python 版本與 venv 由各人自己管） |
| 逆向工程 | Ghidra 12.2 與 JDK 25（給 rea plugin 反編譯原生程式） |
| LSP | rust-analyzer、gopls、pyright、typescript-language-server |
| Claude plugin | 見 [`plugins.txt`](plugins.txt)：mattpocock-skills、pstack、impeccable、ui-ux-pro-max、rea、rust-analyzer-lsp、gopls-lsp、pyright-lsp、typescript-lsp |
| MCP | codegraph（含 `UserPromptSubmit` hook；在專案裡跑 `codegraph init` 後才有作用）；rea（隨 rea plugin 一起裝，原生反編譯用預裝的 Ghidra） |
| repo 管理 | `mr`（myrepos）、`tokei` |
| 其他 | git、tmux、ripgrep、fd、fzf、jq、neovim、vim、htop、build-essential 等 |

---

## 取得與安裝

這是部署型服務：image 在 Docker Hub（`overmindyuan/cdy_agent`、`overmindyuan/cdy_agent_egress`），用 [`compose.hub.yaml`](compose.hub.yaml) 架起來。

### 系統需求

| 項目 | 需求 |
| :--- | :--- |
| 主機 | 能跑 Docker Compose 的 linux/amd64 主機（image 只建 amd64） |
| 資源 | agent 容器上限 6 CPU、16 GB 記憶體；admin 容器上限 4 CPU、8 GB |
| 對外 | 一條 Cloudflare Tunnel 與 Cloudflare Access（真正擋人的門） |

### 最短部署路徑

1. 建資料目錄並交給 `3000:3000`（tmux、admin-ssh、家目錄的 `.ssh` 要 700）：
   ```sh
   sudo mkdir -p /path/to/home /path/to/workspace
   sudo chown -R 3000:3000 /path/to/home /path/to/workspace
   sudo install -d -o 3000 -g 3000 -m 700 /path/to/tmux /path/to/admin-ssh /path/to/home/.ssh
   ```
2. 把 `compose.hub.yaml` 的 `/path/to/...` 換成實際路徑，視需要改 `AGENT_USERS`、`AGENT_ADMINS`。
3. 準備兩個變數：`TUNNEL_TOKEN`（Cloudflare Tunnel 的權杖）與 `ADMIN_PASSWORD_HASH`（admin 密碼雜湊）。
4. 部署：
   ```sh
   docker compose -f compose.hub.yaml up -d
   ```
5. 在 Cloudflare 設 Tunnel 的兩條 public hostname 與兩個 Access Application。

產生密碼雜湊、Cloudflare 設定、admin 的 GitHub 金鑰、更新與回滾，見 [docs/DEPLOY.md](docs/DEPLOY.md)。

---

## 快速開始

1. 打開 `https://<網域>/`，通過 Cloudflare Access → 看到「輸入工號」。
2. 輸入你的工號（例如 `USER1`）→ 進到你的 tmux session 選單。
3. 開一個新 session → 目錄是 `/workspace/USER1`。
4. 第一次使用時，由一個人在終端機裡分別執行 `claude`、`gemini`、`codex` 登入 → 憑證存在共用家目錄，之後所有人、重建容器都不用重新登入。
5. 在 session 裡打 `claude` → 開始使用。

---

## 操作指南

#### 說明頁

在選單按 `?`（或 `h`），或在 shell 裡打 `agent-help`：列出選單與 tmux 快捷鍵、三個 Agent、所有已安裝的 Claude plugin 與技能（即時讀取實際安裝內容）、MCP（含 plugin 自帶的，例如 rea）、語言工具、常用工具、目錄與網路限制。用 less 顯示，`q` 離開、`/` 搜尋。

每個技能標註觸發方式：〔自動〕Claude 依需求自己判斷使用、〔被動〕由其他技能載入（pstack 的 principle-* 由 `/poteto-mode` 載入）、〔手動〕要自己打 `/名稱`。有子指令的技能（目前是 impeccable）會即時讀取它 SKILL.md 裡的指令表，依分類列出，已棄用的不列。

技能說明的中文對照在 [`skills-zh.json`](skills-zh.json)（key 是 `plugin名稱/技能名稱`）。plugin 更新後多出來、還沒翻譯的技能會顯示原文，補進這個檔案即可。

#### 用自己的 git 身分

每個工號可以用自己的 GitHub 帳號，同時使用互不干擾。在自己工號的 tmux session 裡執行一次：

```sh
agent-git-setup
```

它會問名字與 email、產生 SSH 金鑰並印出公鑰（貼到自己的 GitHub → Settings → SSH keys，類型選 Authentication Key），然後：

- `/workspace/<工號>/.agent/gitconfig`：自己的 `user.name`、`user.email`，以及把 GitHub 的 https 網址改走 SSH。
- 共用的 `~/.gitconfig` 加 `includeIf "gitdir:/workspace/<工號>/"`，自己目錄底下的 repo 自動套用。
- `GIT_SSH_COMMAND=agent-git-ssh` 依 session 的工號挑 `/workspace/<工號>/.agent/ssh/id_ed25519`，`git clone` 也會用自己的金鑰。

測試：`agent-git-ssh -T git@github.com`（直接打 `ssh` 不會用到工號的金鑰）。設定後自己目錄底下連 GitHub 一律走 SSH，公鑰沒貼到 GitHub 前 clone／pull 會 `Permission denied`。admin 容器不受影響，照用 admin 專用的 `~/.ssh`。

#### admin 入口

`https://<網域>/admin` 只收 `AGENT_ADMINS` 裡的工號，輸入工號後還要密碼（錯 3 次鎖 30 秒）。進去後：

- 選單列出所有工號的 session（標 `[工號]`），附接別人的一律多重附接、不踢人。附接進去後指令是在**同仁的 agent 容器裡**執行，那裡看不到 `/repos`。
- 新 session 的預設目錄是 `/repos`（放所有 repo 的上層目錄），可用 `mr`、`tokei` 管理各 repo。
- 連 GitHub 用 admin 專用的 SSH 金鑰，同仁的容器看不到它。

#### 對外連線

容器裡已經設好 `HTTP(S)_PROXY` 與 SSH 的 `ProxyCommand`，大部分工具不用另外設定：

- HTTP／HTTPS：三個 Agent、npm、pip/uv、cargo、go、git、curl 都會自動走 proxy。
- SSH：proxy 只放行 CONNECT 到 22 與 443。`git@github.com` 會自動改走 `ssh.github.com:443`。
- 其他協定（資料庫、自訂埠的 TCP、ping）**預設不通**。

---

## 已知限制

- **工號只是「軟區分」**：防止大家搶同一個畫面，不是權限控管。所有人在容器裡都是同一個 Linux 帳號 `dev`，共用同一份 Agent 登入（同一份訂閱額度與對話紀錄），也看得到彼此的 workspace 與 git 金鑰；懂 tmux 的人可以自己 attach 到別人的 socket。只適合彼此信任的同事。
- **admin 密碼也是軟區分**：一般工號在自己的容器裡看不到 `/repos`，但讀得到環境變數裡的密碼雜湊。真正擋人的是 Cloudflare Access。
- **真正的門是 Cloudflare Access**。ttyd 本身沒有密碼（`TTYD_CREDENTIAL` 可以選填第二道）。
- **程式碼要勤 commit／push**：這是防止 Agent 誤刪檔案最有效的保護。

---

## 常見問題

#### 輸入工號後被拒絕

只有 `AGENT_USERS`（admin 入口是 `AGENT_ADMINS`）裡的工號能進來，而且工號只允許英數字、底線、連字號。請管理者把你的工號加進去並重新部署；`/workspace/<工號>` 會自動建立。

#### 連不到資料庫或公司內網的機器

這是刻意的：容器沒有對外路由，所有連線經 egress proxy，而 proxy 擋掉了私網段（RFC1918、100.64/10、169.254/16、127/8 等）與 22、443 以外的 CONNECT。

#### git clone 或 pull 出現 `Permission denied (publickey)`

跑過 `agent-git-setup` 之後，自己目錄底下連 GitHub 一律走 SSH。把它印出的公鑰貼到自己的 GitHub → Settings → SSH keys，再用 `agent-git-ssh -T git@github.com` 測試。

#### 想知道 Agent 連了哪些地方

管理者在主機上看 egress 容器的 log：`docker logs <egress 容器>`。

---

## 授權

本專案採用 PolyForm Noncommercial License 1.0.0 授權，詳見 [LICENSE](LICENSE)。

---

## 開發者

想修改或自行建置？請看 [docs/DEVELOPER.md](docs/DEVELOPER.md)。
變更紀錄請看 [docs/CHANGELOG.md](docs/CHANGELOG.md)。

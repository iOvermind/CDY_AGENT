# CDY_AGENT

給同仁用的 AI Agent 終端機容器。瀏覽器經 Cloudflare Access 進到 ttyd，輸入工號後進入該工號專屬的
tmux 選單，在裡面用 Claude Code、Gemini CLI、Codex CLI。

```
瀏覽器 → Cloudflare Access → cloudflared → http://agent:7681（ttyd）
  → 輸入工號（只接受 AGENT_USERS 裡的值）
  → 該工號專屬的 tmux socket（sock_<工號>）與 session 選單
  → 新 session 的目錄：/workspace/<工號>
```

## 工號與 admin

| ENV | 說明 |
|---|---|
| `AGENT_USERS` | 一般工號，逗號分隔。輸入後直接進自己的 tmux 選單，預設目錄 `/workspace/<工號>` |
| `AGENT_ADMINS` | admin 工號，逗號分隔。輸入後要密碼；選單會列出**所有工號**的 session（標 `[工號]`），附接別人的一律多重附接、不踢人；預設目錄 `/repos`（NAS 的整個 `repos`） |
| `AGENT_ADMIN_PASSWORD_HASH` | admin 密碼的 SHA-512 crypt 雜湊。留空則 admin 無法登入。密碼錯 3 次鎖 30 秒 |

產生雜湊（在 NAS 上跑；Mac 內建的 LibreSSL 不支援 `-6`）。輸出已經把 `$` 轉成 compose 要的 `$$`，
整串用單引號貼進 `AGENT_ADMIN_PASSWORD_HASH: '...'`：

```sh
openssl passwd -6 | sed 's/\$/$$/g'
```

admin 密碼一樣是**軟區分**：一般工號在容器裡也能直接 `cd /repos`、attach 別人的 socket、讀到環境變數裡的雜湊。

## 安全邊界（務必知道）

- **工號只是「軟區分」**：防止大家搶同一個畫面，不是權限控管。所有人在容器裡都是同一個 Linux 帳號
  `dev`，共用同一份 Agent 登入（同一份訂閱額度與對話紀錄），也看得到彼此的 workspace；懂 tmux 的人
  可以自己 attach 到別人的 socket。只適合彼此信任的同事。
- **真正的門是 Cloudflare Access**。ttyd 本身沒有密碼（`TTYD_CREDENTIAL` 可以選填第二道）。
- **內網隔離**：agent 只接 `internal` 網路，沒有對外路由。所有對外連線經 egress proxy（squid），
  用黑名單擋掉私網段（RFC1918、100.64/10、169.254/16、127/8 等），所以 LAN 上的設備與 NAS 本身都連不到。
  不需要動主機防火牆。
- **程式碼要勤 commit / push**：這是防止 Agent 誤刪檔案最有效的保護。

## 裝了什麼

| 類別 | 內容 |
|---|---|
| Agent CLI | Claude Code、Gemini CLI、Codex CLI（不鎖版本，每次 build 拿最新） |
| 語言工具鏈 | Node 24、Rust stable（rust-analyzer、clippy、rustfmt）、Go、uv（Python 版本與 venv 由各人自己管） |
| LSP | rust-analyzer、gopls、pyright、typescript-language-server |
| Claude plugin | 見 [`plugins.txt`](plugins.txt)：mattpocock-skills、pstack、impeccable、rust-analyzer-lsp、gopls-lsp、pyright-lsp、typescript-lsp |
| MCP | codegraph（含 `UserPromptSubmit` hook；在專案裡跑 `codegraph init` 後才有作用） |
| repo 管理 | `mr`（myrepos）、`tokei` |
| 其他 | git、tmux、ripgrep、fd、fzf、jq、neovim、vim、htop、build-essential 等 |

Claude 的 marketplace 與 plugin 是**容器啟動時**由 `agent-seed` 補齊的（只補還沒有的，不覆蓋已登入的
憑證），log 在 `~/.cache/agent-seed.log`。`~/.claude/settings.json` 只在不存在時寫入預設值
（繁體中文、dark theme、codegraph hook）。

## 對外連線

容器裡已經設好 `HTTP(S)_PROXY` 與 SSH 的 `ProxyCommand`，大部分工具不用另外設定：

- HTTP / HTTPS：三個 Agent、npm、pip/uv、cargo、go、git、curl 都會自動走 proxy。
- SSH：proxy 只放行 CONNECT 到 22 與 443。`git@github.com` 會自動改走 `ssh.github.com:443`。
- 其他協定（資料庫、自訂 port 的 TCP、ping）**預設不通**。
- 看 agent 連了哪些地方：`docker logs <egress 容器>`。

## 部署（NAS / Dockhand）

1. 第一次：建資料目錄並交給 3000:3000。
   ```sh
   sudo mkdir -p /path/to/home
   sudo chown -R 3000:3000 /path/to /path/to/workspace
   ```
2. 在 Dockhand 貼 [`compose.hub.yaml`](compose.hub.yaml)，填 `TUNNEL_TOKEN`，視需要修改 `AGENT_USERS`。
3. Cloudflare：Tunnel 的 public hostname 的 service 填 `http://agent:7681`，再在 Access 設定誰能進來。
4. 進終端機後，由一個人登入三個 Agent（`claude`、`gemini`、`codex`），憑證存在
   `/path/to/home`，重建容器不用重新登入。

更新：push 到 `main` 後 GitHub Actions 會建好並推上 Docker Hub（`overmindyuan/cdy_agent`、
`overmindyuan/cdy_agent_egress`），每週一也會自動重建一次讓 CLI 跟上新版。在 Dockhand 重新部署就會拉到
新的 `latest`；回滾就把 tag 改成 `sha-xxxxxxx`。

GitHub Actions 需要的 Secrets：`DOCKERHUB_USERNAME`、`DOCKERHUB_TOKEN`。

## 本機驗證

```sh
./build.sh
docker compose up -d
open http://127.0.0.1:7681
```

資料放在 `./data`（已在 `.gitignore`）。本機版多一個 `peek` 服務把 `127.0.0.1:7681` 轉進 internal 網路。

手動推 Docker Hub（備案，Apple Silicon 上會比較慢）：`./push-hub.sh`。

## 檔案

| 路徑 | 用途 |
|---|---|
| `Dockerfile` | agent image |
| `rootfs/usr/local/bin/agent-entrypoint` | 補齊家目錄、建立工號 workspace、背景同步技能、啟動 ttyd |
| `rootfs/usr/local/bin/agent-login` | 第一層：輸入工號 |
| `rootfs/usr/local/bin/agent-selector` | 第二層：工號專屬的 tmux session 選單 |
| `rootfs/usr/local/bin/agent-seed` | 依 `plugins.txt` 補齊 Claude marketplace / plugin、註冊 codegraph MCP |
| `rootfs/etc/tmux.conf` | 全域 tmux 設定 |
| `rootfs/etc/ssh/ssh_config.d/egress.conf` | SSH 經 proxy 出去 |
| `egress/` | egress proxy（squid）image 與黑名單設定 |
| `compose.hub.yaml` | 正式部署（Dockhand） |
| `compose.yaml` | 本機驗證 |

## 授權

[PolyForm Noncommercial 1.0.0](LICENSE)

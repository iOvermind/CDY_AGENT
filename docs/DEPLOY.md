# 《代理終端機》(CDY_AGENT) 部署

> 正式部署的細節。最短部署路徑見 [README.md](../README.md) 的「取得與安裝」；改程式見 [DEVELOPER.md](DEVELOPER.md)。

---

## 1. 架構

同一個網域兩個入口、兩個容器（同一個 image，用 `AGENT_ROLE` 區分），再加 egress proxy 與 cloudflared：

| 入口 | 容器 | 收誰 | 掛載 |
| :--- | :--- | :--- | :--- |
| `https://<網域>/` | `agent`（`AGENT_ROLE=user`） | `AGENT_USERS` | `/workspace`（同仁的程式碼） |
| `https://<網域>/admin` | `admin`（`AGENT_ROLE=admin`、`TTYD_BASE_PATH=/admin`） | `AGENT_ADMINS` + 密碼 | `/repos`（放所有 repo 的上層目錄）、`/workspace` |
| — | `egress`（squid） | agent、admin 的對外連線 | 無（設定烤在 image 裡） |
| — | `cloudflared` | Cloudflare Tunnel | 無 |

- **一般同仁的容器裡根本沒有 `/repos`**。這是拆兩個容器的原因：容器裡大家都是同一個 Linux 帳號 `dev`，同一個容器擋不住誰 `cd` 到哪。
- 兩個容器共用家目錄（Agent 登入一次兩邊都能用、`~/.mrconfig` 同一份）與 tmux socket 目錄（`/path/to/tmux`），admin 才附接得到同仁的 session。
- **網路**：agent、admin 只接 `internal` 網路（沒有對外路由，也連不到區域網路與主機本身），對外一律經 egress proxy；egress 用黑名單擋掉私網段（RFC1918、100.64/10、169.254/16、127/8 等），CONNECT 只放行 22 與 443。不需要動主機防火牆。

## 2. 資料目錄

第一次部署前建好，交給 `3000:3000`（容器裡 `dev` 的 UID/GID）。tmux 目錄要 700，否則 tmux 拒絕使用；`.ssh` 類的目錄先建好，免得 Docker 建成 root 擁有的掛載點：

```sh
sudo mkdir -p /path/to/home /path/to/workspace
sudo chown -R 3000:3000 /path/to/home /path/to/workspace
sudo install -d -o 3000 -g 3000 -m 700 /path/to/tmux /path/to/admin-ssh /path/to/home/.ssh
```

| host 路徑 | 掛到 | 誰用 | 內容 |
| :--- | :--- | :--- | :--- |
| `/path/to/workspace` | `/workspace` | agent、admin | 同仁的程式碼：`/workspace/<工號>`（啟動時自動建立） |
| `/path/to/home` | `/home/dev` | agent、admin | Agent 登入憑證、plugin、個人設定、uv/cargo/go 的快取 |
| `/path/to/tmux` | `/tmp/tmux-3000` | agent、admin | tmux socket |
| `/path/to/repos` | `/repos` | admin | 放所有 repo 的上層目錄 |
| `/path/to/admin-ssh` | `/home/dev/.ssh` | admin | admin 專用的 SSH 金鑰（蓋在共用家目錄上面） |

## 3. 變數

| 變數 | 在哪 | 說明 |
| :--- | :--- | :--- |
| `TUNNEL_TOKEN` | cloudflared | Cloudflare Zero Trust → Networks → Tunnels 拿到的權杖 |
| `ADMIN_PASSWORD_HASH` | admin（→ `AGENT_ADMIN_PASSWORD_HASH`） | admin 密碼雜湊，產生方式見 §4 |
| `AGENT_USERS` | agent | 可登入的工號，逗號分隔（例 `USER1,USER2`）。改完重新部署即可 |
| `AGENT_ADMINS` | admin | admin 工號，逗號分隔（例 `ADMIN1`） |
| `TTYD_CREDENTIAL` | agent、admin | ttyd 的第二道帳密（`user:password`），留空就不啟用 |

工號只允許英數字、底線、連字號。

## 4. admin 密碼

產生雜湊（在主機上跑；macOS 內建的 LibreSSL 不支援 `-6`）。輸出是 base64，裡面沒有 `$`，貼進 Dockhand 的變數 `ADMIN_PASSWORD_HASH` 不會被當成變數展開：

```sh
openssl passwd -6 | base64 -w0; echo
```

也接受原樣的 `$6$...`（直接寫在 compose 裡時要把 `$` 寫成 `$$`）。密碼錯 3 次鎖 30 秒。

## 5. Cloudflare

Tunnel 的 public hostname 設兩條，**`/admin` 那條排前面**：

| hostname | path | service |
| :--- | :--- | :--- |
| `<網域>` | `admin*` | `http://admin:7681` |
| `<網域>` | （空） | `http://agent:7681` |

Access 設兩個 Application：一個給 `/`（放同仁），一個同網域、path 填 `admin`（只放 admin）。真正擋人的是 Access，ttyd 本身沒有密碼。

## 6. admin 的 GitHub 金鑰

admin 容器另外掛 `/path/to/admin-ssh` 到 `~/.ssh`，並用 `GIT_CONFIG_*` 環境變數把 `https://github.com/` 改走 SSH；SSH 經 egress proxy 走 `ssh.github.com:443`。同仁的 agent 容器看不到這把 key，也沒有這個改寫。在 admin 入口第一次設定：

```sh
ssh-keygen -t ed25519 -C cdy-agent-admin     # 公鑰貼到 GitHub → Settings → SSH and GPG keys
ssh -T git@github.com                        # 第一次問指紋輸入 yes
```

## 7. 部署（Dockhand）

1. 照 §2 建資料目錄。
2. 在 Dockhand 貼 [`compose.hub.yaml`](../compose.hub.yaml)，把 `/path/to/...` 換成實際路徑，填 `TUNNEL_TOKEN`、`ADMIN_PASSWORD_HASH`，視需要改 `AGENT_USERS`、`AGENT_ADMINS`。
3. 照 §5 設 Cloudflare。
4. 進終端機後，由一個人登入三個 Agent（`claude`、`gemini`、`codex`），憑證存在 `/path/to/home`，重建容器不用重新登入。

完成狀態：`docker ps` 看到 agent、admin 為 `healthy`（健康檢查是 ttyd 回應 `http://127.0.0.1:7681/`），cloudflared 在兩者 healthy 後才啟動。

## 8. 更新與回滾

- image 由 GitHub Actions 建好推上 Docker Hub：push 到 `main` 推 `latest` 與 `sha-xxxxxxx`；推 `v1.2.3` 這種 tag 另推 `1.2.3`；每週一也會自動重建一次讓 CLI 跟上新版。
- `compose.hub.yaml` 設了 `pull_policy: always`，在 Dockhand 重新部署就會拉到新的 `latest`。
- 回滾：把 image 的 tag 改成 `sha-xxxxxxx` 或版本號（例 `1.0.0`）再部署。
- 查線上跑的是哪一版：`docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' <agent 容器>`。

## 9. 看連線紀錄

egress 把每一筆連線印到 stdout：`docker logs <egress 容器>`。

Claude 的 marketplace 與 plugin 在容器啟動時由 `agent-seed` 補齊，log 在容器裡的 `~/.cache/agent-seed.log`。

# Product

<!-- impeccable:product-schema 1 -->

## Platform

none

（瀏覽器裡的 ttyd 終端機：介面是 tmux 與文字選單，沒有圖形介面。）

## Users

- **同仁（一般工號）**：在瀏覽器裡開終端機，用 Claude Code、Gemini CLI、Codex CLI 改自己 `/workspace/<工號>` 底下的程式碼，用自己的 GitHub 帳號 commit 與 push。
- **admin**：從 `/admin` 入口進來，看得到並附接所有工號的 session，在 `/repos` 管理所有 repo。

## Product Purpose

《代理終端機》(CDY_AGENT) 提供一個環境，供同仁使用 AI Agent 開發：打開瀏覽器輸入工號，就能在自己的工作階段裡用 Claude Code、Gemini CLI、Codex CLI 改程式碼；工具鏈、plugin 與 Agent 登入由一個地方集中維護。

成功＝同仁只用瀏覽器和工號就能開始用三個 Agent，不需要在自己電腦上安裝任何東西；容器連不到區域網路上的設備與主機本身。

## Positioning

內部工具：一個集中的 AI Agent 開發環境。三個 Agent 共用同一份登入與訂閱，工具鏈與 plugin 由 image 統一提供，每週自動重建跟上新版；同仁的電腦上不必安裝任何東西。

## Operating Context

- 部署在內部主機上，用 Dockhand 貼 `compose.hub.yaml` 管理；image 從 Docker Hub 拉。
- 對外經 Cloudflare Tunnel，Cloudflare Access 決定誰能進來，`/` 與 `/admin` 各一個 Access Application。
- 容器只接沒有對外路由的內部網路，對外一律經 egress proxy，私網段全擋。
- 使用者彼此信任：工號只是軟區分，所有人在容器裡是同一個 Linux 帳號 `dev`。

## Capabilities and Constraints

- 只收 `AGENT_USERS`／`AGENT_ADMINS` 裡的工號；工號只允許英數字、底線、連字號，不分大小寫。
- 每個工號有自己的 tmux socket、session 選單與 `/workspace/<工號>`。
- admin 要密碼（錯 3 次鎖 30 秒），看得到所有工號的 session；`/repos` 只掛在 admin 容器。
- 每個工號可用 `agent-git-setup` 設定自己的 git 身分與 SSH 金鑰。
- 對外只放行 HTTP／HTTPS 與 CONNECT 到 22、443；其他協定不通，私網段不通。
- 約束：不是權限控管。共用帳號、共用 Agent 登入，看得到彼此的 workspace 與金鑰；真正的門是 Cloudflare Access。
- 約束：image 只建 linux/amd64。
- 工號數量沒有上限：`AGENT_USERS` 列多少就收多少；資源由所有同仁共用（agent 容器上限 6 CPU、16 GB）。

## Evidence on Hand

- 實際部署設定：`compose.hub.yaml`；本機驗證：`compose.yaml`。
- 預裝的 plugin 清單：`plugins.txt`；技能中文說明：`skills-zh.json`。
- 容器行為：`rootfs/usr/local/bin/`（登入、選單、說明頁、git 身分、啟動補齊）。
- 沒有：使用統計、同仁的回饋紀錄、正式的使用規範文件。

# CDY_AGENT：給同仁用的 AI Agent 終端機容器。
#
# ttyd 進來先輸入工號，再進到該工號專屬的 tmux 選單。所有人共用 dev 這個帳號與同一份
# Agent 登入（軟區分，不是多租戶隔離）。對外連線一律經過同一個 stack 的 egress proxy。
#
# 會被掛載蓋掉的路徑：/home/dev 與 /workspace。所以工具鏈一律裝在 /opt、/usr/local，
# 不放家目錄——放進 /home/dev 的東西在正式環境裡會被 host path 蓋掉、看不到。

FROM node:24-bookworm-slim

ARG UID=3000
ARG GID=3000
ARG TTYD_VERSION=1.7.7
ARG GO_VERSION=1.27.4
# Ghidra 給 rea plugin 做原生程式反編譯用。REA 要求 Ghidra >= 12.2 與 JDK 25。
# REA_GHIDRA_CHECKPOINT_DIR（下面 ENV）讓 rea 把分析結果與改名、註解存在家目錄，重開同一個檔直接接續；
# 目錄由 agent-entrypoint 建立並設成 700（REA 要求只有自己能讀寫）。
# 升版時三個值一起改：版本、壓縮檔日期、官方 release 頁上的 SHA-256。
ARG GHIDRA_VERSION=12.2
ARG GHIDRA_DATE=20261016
ARG GHIDRA_SHA256=2c2cd776db3c1f6a097ba418922378ac3649cadd5e844a6f5f088ae628a7be67

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    NPM_CONFIG_PREFIX=/opt/npm-global \
    RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    GOPATH=/home/dev/go \
    GOTOOLCHAIN=local \
    JAVA_HOME=/opt/jdk \
    GHIDRA_INSTALL_DIR=/opt/ghidra \
    REA_GHIDRA_CHECKPOINT_DIR=/home/dev/.cache/rea/ghidra-checkpoints

ENV PATH="/opt/jdk/bin:/opt/npm-global/bin:/opt/rust/cargo/bin:/usr/local/go/bin:/opt/go-tools/bin:/home/dev/go/bin:/home/dev/.local/bin:${PATH}"

# 基礎工具、搜尋與編輯器、Rust/Go 編譯需要的工具鏈依賴，以及工號選單用的 python3（只給選單用，
# 同仁的專案請用 uv 自己裝 Python 版本與 venv）。
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        fd-find \
        file \
        fzf \
        git \
        htop \
        jq \
        less \
        libssl-dev \
        myrepos \
        ncurses-term \
        neovim \
        netcat-openbsd \
        openssh-client \
        openssl \
        pkg-config \
        procps \
        python3 \
        ripgrep \
        tmux \
        tree \
        unzip \
        vim \
        wget \
        xz-utils \
        zip \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# ttyd 官方靜態執行檔（Debian 套件庫沒有）。
RUN ARCH="$(uname -m)" \
    && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${ARCH}" -o /usr/local/bin/ttyd \
    && chmod 755 /usr/local/bin/ttyd

# Go 官方 tarball。
RUN ARCH="$(dpkg --print-architecture)" \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz

# rea 的 Ghidra：JDK 25（Temurin，取 25 的最新修正版）與 Ghidra 官方壓縮檔（固定版本、驗 SHA-256）。
# 官方壓縮檔只附 Linux x64 的原生反編譯器：正式 image（amd64）可以反編譯；本機 arm64 建的版本
# 裝得起來，但 rea 會回報沒有反編譯器。
RUN case "$(dpkg --print-architecture)" in arm64) JDK_ARCH=aarch64 ;; *) JDK_ARCH=x64 ;; esac \
    && curl -fsSL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/${JDK_ARCH}/jdk/hotspot/normal/eclipse" -o /tmp/jdk.tar.gz \
    && mkdir -p /opt/jdk && tar -C /opt/jdk --strip-components=1 -xzf /tmp/jdk.tar.gz && rm /tmp/jdk.tar.gz \
    && curl -fsSL "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip" -o /tmp/ghidra.zip \
    && echo "${GHIDRA_SHA256}  /tmp/ghidra.zip" | sha256sum -c - \
    && unzip -q /tmp/ghidra.zip -d /opt && rm /tmp/ghidra.zip \
    && mv "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC" /opt/ghidra \
    && java -version && test -x /opt/ghidra/support/analyzeHeadless

# uv：同仁自己用 `uv python install`、`uv venv` 管 Python 版本，裝在家目錄底下，跨重建保留。
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# 非 root 使用者 dev，UID/GID 對齊 NAS 上的資料擁有者（3000:3000）。
RUN userdel -r node \
    && (groupdel node 2>/dev/null || true) \
    && groupadd -g "${GID}" dev \
    && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash dev \
    && mkdir -p /opt/npm-global /opt/rust /opt/go-tools /opt/agent /workspace \
    && chown -R dev:dev /opt/npm-global /opt/rust /opt/go-tools /workspace

# tmux 開的是 login shell，Debian 的 /etc/profile 會把 PATH 重設成系統預設、蓋掉上面 ENV 的
# PATH（claude、cargo、go 都會找不到）。在 profile.d 補回同一份 PATH。
RUN printf 'export PATH="%s"\n' "${PATH}" > /etc/profile.d/00-agent-path.sh

COPY --chmod=755 rootfs/usr/local/bin/ /usr/local/bin/
COPY --chmod=644 rootfs/etc/tmux.conf /etc/tmux.conf
COPY --chmod=644 rootfs/etc/ssh/ssh_config.d/ /etc/ssh/ssh_config.d/
COPY --chmod=644 plugins.txt claude-settings.json skills-zh.json /opt/agent/

USER dev
WORKDIR /workspace

# Rust：stable + rust-analyzer/clippy/rustfmt。RUSTUP_HOME、CARGO_HOME 在 /opt/rust 且屬於 dev，
# 容器內可以直接 `rustup update`。
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal \
        --default-toolchain stable --component rust-analyzer,clippy,rustfmt \
    && rustup --version && rust-analyzer --version

# tokei（程式碼行數統計）。官方沒有提供 Linux 執行檔，用 cargo 編；編完把 registry 快取清掉。
RUN cargo install --locked tokei \
    && rm -rf "${CARGO_HOME}/registry" "${CARGO_HOME}/git" \
    && tokei --version

# gopls 裝到 /opt/go-tools/bin；建置用的 GOPATH 與快取丟到 /tmp，不留在 image 裡。
RUN GOBIN=/opt/go-tools/bin GOPATH=/tmp/gopath GOCACHE=/tmp/gocache \
        go install golang.org/x/tools/gopls@latest \
    && GOPATH=/tmp/gopath go clean -modcache \
    && rm -rf /tmp/gopath /tmp/gocache \
    && gopls version

# 三個 AI Agent CLI、codegraph，以及 Claude LSP plugin 需要的語言伺服器。
RUN npm install -g \
        @anthropic-ai/claude-code \
        @google/gemini-cli \
        @openai/codex \
        @colbymchenry/codegraph \
        pyright \
        typescript \
        typescript-language-server \
    && npm cache clean --force \
    && rm -rf /home/dev/.npm

# 執行期對外一律走 egress proxy（見 egress/squid.conf）。放在最後：build 階段還沒有 egress 可用。
# 容器本身只接 internal 網路、沒有對外路由，
# 不理會這些變數的程式就是連不出去。大小寫都設：git/curl 只認小寫的 http_proxy。
# NODE_USE_ENV_PROXY 讓 Node 內建的 fetch 也走 proxy（Node 24 起支援）。
ENV HTTP_PROXY=http://egress:3128 \
    HTTPS_PROXY=http://egress:3128 \
    http_proxy=http://egress:3128 \
    https_proxy=http://egress:3128 \
    NO_PROXY=localhost,127.0.0.1,::1,agent,egress \
    no_proxy=localhost,127.0.0.1,::1,agent,egress \
    NODE_USE_ENV_PROXY=1 \
    AGENT_SSH_PROXY=egress:3128 \
    AGENT_ADMIN_HOME=/repos \
    GIT_SSH_COMMAND=agent-git-ssh

EXPOSE 7681

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -s --noproxy '*' -o /dev/null http://127.0.0.1:7681/ || exit 1

# 版本號由建置時傳入（單一來源是 VERSION，見 docs/DEVELOPER.md §7）。放在最後，不影響前面的快取。
ARG VERSION=dev
LABEL org.opencontainers.image.version=$VERSION

ENTRYPOINT ["/usr/local/bin/agent-entrypoint"]

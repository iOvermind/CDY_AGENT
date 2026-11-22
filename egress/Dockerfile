# CDY_AGENT 的 egress proxy。設定檔烤進 image，部署時不需要掛載任何檔案。
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends squid \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=644 squid.conf /etc/squid/squid.conf

# 以 squid 套件建立的 proxy 帳號跑，不需要任何 capability。
USER proxy
EXPOSE 3128

CMD ["squid", "-N", "-d", "1", "-f", "/etc/squid/squid.conf"]

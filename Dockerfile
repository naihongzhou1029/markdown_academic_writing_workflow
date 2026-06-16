FROM dalibo/pandocker:latest-full

# Install jq and curl for translation scripts
# Install Node.js and npm for mermaid-cli
# Install basic dependencies for Puppeteer/Chrome (required by mermaid-cli)
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends \
        jq curl nodejs npm \
        ca-certificates fonts-liberation fonts-noto-color-emoji \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
        libgbm1 libpangocairo-1.0-0 libcairo-gobject2 \
        libgtk-3-0 libgdk-pixbuf2.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install mermaid-cli globally
RUN npm install -g @mermaid-js/mermaid-cli

# Install Chrome headless shell that Puppeteer expects
# Install it in a system-wide location accessible to all users
RUN mkdir -p /opt/puppeteer-cache && \
    chmod 777 /opt/puppeteer-cache && \
    PUPPETEER_CACHE_DIR=/opt/puppeteer-cache npx --yes puppeteer browsers install chrome-headless-shell && \
    chmod -R 777 /opt/puppeteer-cache && \
    find /opt/puppeteer-cache -type f -exec chmod 755 {} \; && \
    find /opt/puppeteer-cache -type d -exec chmod 755 {} \;

# Set environment variables for Puppeteer
ENV PUPPETEER_CACHE_DIR=/opt/puppeteer-cache

# Resolve the installed Chrome executable path and write Puppeteer config
RUN CHROME_PATH=$(find /opt/puppeteer-cache -name "chrome-headless-shell" -type f | head -1) && \
    echo "{\"executablePath\": \"${CHROME_PATH}\", \"args\": [\"--no-sandbox\", \"--disable-setuid-sandbox\"]}" > /etc/puppeteer-config.json && \
    chmod 644 /etc/puppeteer-config.json
ENV PUPPETEER_CONFIG_FILE=/etc/puppeteer-config.json

# Install libasound2 for Chromium (Ubuntu 24.04 uses libasound2t64)
RUN apt-get update -qq && \
    (apt-get install -y -qq libasound2 2>/dev/null || \
     apt-get install -y -qq libasound2t64 2>/dev/null || true) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install placeins LaTeX package for FloatBarrier support.
# `tlmgr install` is avoided on purpose: once TeX Live 2026 shipped, every live tlnet
# mirror became newer than the base image's local TL2025 database, and tlmgr refuses
# cross-release operations ("Local TeX Live is older than remote repository"). Since
# placeins is a single self-contained .sty file, drop it straight into TEXMFLOCAL and
# refresh the filename database — release-independent and mirror-independent.
RUN TEXMFLOCAL="$(kpsewhich -var-value TEXMFLOCAL)" && \
    mkdir -p "${TEXMFLOCAL}/tex/latex/placeins" && \
    curl -fsSL https://mirrors.ctan.org/macros/latex/contrib/placeins/placeins.sty \
        -o "${TEXMFLOCAL}/tex/latex/placeins/placeins.sty" && \
    mktexlsr

# Keep the same entrypoint as base image
ENTRYPOINT [""]


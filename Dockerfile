FROM dalibo/pandocker:latest-full

# Install jq and curl for translation scripts
# Install Node.js and npm for mermaid-cli
# Install basic dependencies for Puppeteer/Chrome (required by mermaid-cli)
# Puppeteer will download its own Chromium, but needs some system libraries
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
# Puppeteer will download its own Chromium automatically
RUN npm install -g @mermaid-js/mermaid-cli

# Create Puppeteer config file to run Chromium with --no-sandbox (required when running as root in Docker)
RUN echo '{"args": ["--no-sandbox", "--disable-setuid-sandbox"]}' > /etc/puppeteer-config.json
ENV PUPPETEER_CONFIG_FILE=/etc/puppeteer-config.json

# Install libasound2 for Chromium (Ubuntu 24.04 uses libasound2t64)
RUN apt-get update -qq && \
    (apt-get install -y -qq libasound2 2>/dev/null || \
     apt-get install -y -qq libasound2t64 2>/dev/null || true) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Keep the same entrypoint as base image
ENTRYPOINT [""]


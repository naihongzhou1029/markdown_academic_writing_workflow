FROM dalibo/pandocker:latest-full

# Install jq and curl for translation scripts
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends jq curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Keep the same entrypoint as base image
ENTRYPOINT [""]


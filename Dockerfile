FROM fishaudio/fish-speech@sha256:2fad8c46e68a6090943eb05163517dbabf5d5cb79f8aa7cf95272596a6dbb42e
ARG FISH_S2_PRO_REVISION=1de9996b6be38b745688de084d87a5633f714e4e

USER root
WORKDIR /app

# 1. Install curl AND python3-venv (which is required by the HF CLI installer)
RUN apt-get update && apt-get install -y curl python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    /app/.venv/bin/python3 -m ensurepip --upgrade && \
    /app/.venv/bin/python3 -m pip install --no-cache-dir runpod && \
    curl -LsSf https://hf.co/cli/install.sh | bash
    
# 2. Add the HF CLI binary to your PATH
ENV PATH="/root/.local/bin:${PATH}"

# 3. Download the model 

# 4. Copy your local files
RUN --mount=type=cache,target=/root/.cache/huggingface,sharing=locked \
    hf download fishaudio/s2-pro \
      --revision "${FISH_S2_PRO_REVISION}" \
      --cache-dir /root/.cache/huggingface && \
    mkdir -p /app/checkpoints/s2-pro && \
    cp -a "/root/.cache/huggingface/hub/models--fishaudio--s2-pro/snapshots/${FISH_S2_PRO_REVISION}/." /app/checkpoints/s2-pro/
COPY ./src /app/src
RUN chmod +x /app/src/run.sh

# 5. Environment setup
ENV PYTHONPATH="/app:/app/src"

ENTRYPOINT ["/app/src/run.sh"]
FROM fishaudio/fish-speech@sha256:2fad8c46e68a6090943eb05163517dbabf5d5cb79f8aa7cf95272596a6dbb42e
ARG FISH_S2_PRO_REVISION=1de9996b6be38b745688de084d87a5633f714e4e

USER root
WORKDIR /app

# Install the RunPod SDK into Fish Speech's managed virtual environment and the Hugging Face CLI.
RUN apt-get update && apt-get install -y curl python3-venv && \
    apt-get clean && \
    /app/.venv/bin/python3 -m ensurepip --upgrade && \
    /app/.venv/bin/python3 -m pip install --no-cache-dir runpod && \
    curl -LsSf https://hf.co/cli/install.sh | bash

ENV PATH="/root/.local/bin:${PATH}"

# Materialize the exact S2 Pro revision in the final image. Hugging Face snapshots are symlinked
# cache entries, so cp -aL is intentional: the image must contain real checkpoint files, not links
# to a build-cache-only blobs directory.
RUN --mount=type=cache,target=/root/.cache/huggingface,sharing=locked \
    hf download fishaudio/s2-pro \
      --revision "${FISH_S2_PRO_REVISION}" \
      --cache-dir /root/.cache/huggingface && \
    mkdir -p /app/checkpoints/s2-pro && \
    cp -aL "/root/.cache/huggingface/models--fishaudio--s2-pro/snapshots/${FISH_S2_PRO_REVISION}/." /app/checkpoints/s2-pro/ && \
    test -s /app/checkpoints/s2-pro/config.json && \
    test -s /app/checkpoints/s2-pro/codec.pth && \
    test -z "$(find /app/checkpoints/s2-pro -type l -print -quit)"

COPY ./src /app/src
RUN chmod +x /app/src/run.sh

ENV PYTHONPATH="/app:/app/src"

ENTRYPOINT ["/app/src/run.sh"]

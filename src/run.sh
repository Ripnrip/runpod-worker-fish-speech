#!/usr/bin/env bash
set -Eeuo pipefail

FISH_PYTHON="/app/.venv/bin/python3"
FISH_LOG="/tmp/fish.server.log"
FISH_READY_URL="http://127.0.0.1:8080/docs"
MAX_STARTUP_ATTEMPTS=120
STARTUP_INTERVAL_SECONDS=3
FISH_PID=""
HANDLER_PID=""

cleanup() {
    echo "Cleaning up..."
    [[ -n "$FISH_PID" ]] && kill "$FISH_PID" 2>/dev/null || true
    [[ -n "$HANDLER_PID" ]] && kill "$HANDLER_PID" 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

if [[ ! -x "$FISH_PYTHON" ]]; then
    echo "Fish managed Python runtime is unavailable: $FISH_PYTHON" >&2
    exit 1
fi

# Fish Speech dependencies live in the base image’s managed virtual environment.
"$FISH_PYTHON" -u /app/tools/api_server.py \
    --llama-checkpoint-path /app/checkpoints/s2-pro \
    --decoder-checkpoint-path /app/checkpoints/s2-pro/codec.pth \
    --device cuda \
    > >(tee "$FISH_LOG") 2>&1 &
FISH_PID=$!

for ((attempt = 1; attempt <= MAX_STARTUP_ATTEMPTS; attempt++)); do
    if curl --fail --silent --show-error --max-time 2 "$FISH_READY_URL" >/dev/null 2>&1; then
        echo "Fish Speech server is ready after $((attempt * STARTUP_INTERVAL_SECONDS)) seconds."
        break
    fi

    if ! kill -0 "$FISH_PID" 2>/dev/null; then
        echo "Fish Speech server exited during startup. Last server log lines:" >&2
        tail -n 200 "$FISH_LOG" 2>/dev/null || true
        exit 1
    fi

    if (( attempt == MAX_STARTUP_ATTEMPTS )); then
        echo "Fish Speech server did not become ready within $((MAX_STARTUP_ATTEMPTS * STARTUP_INTERVAL_SECONDS)) seconds. Last server log lines:" >&2
        tail -n 200 "$FISH_LOG" 2>/dev/null || true
        exit 1
    fi

    echo "Waiting for Fish Speech server readiness (${attempt}/${MAX_STARTUP_ATTEMPTS})..."
    sleep "$STARTUP_INTERVAL_SECONDS"
done

# Run the handler through the same managed virtual environment.
"$FISH_PYTHON" -u /app/src/handler.py &
HANDLER_PID=$!

# If either critical process exits, terminate the container so RunPod surfaces the failure.
wait -n "$FISH_PID" "$HANDLER_PID"
echo "A critical worker process exited unexpectedly; shutting down..." >&2
kill "$FISH_PID" "$HANDLER_PID" 2>/dev/null || true
exit 1

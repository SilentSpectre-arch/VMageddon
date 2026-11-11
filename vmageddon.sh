
#!/usr/bin/env bash

set -Eeuo pipefail

# VM Chaos Engineering Lab
# Controlled CPU and RAM stress test

DURATION=1000000000
CPU_WORKERS=1000000000
MEMORY_MB=1000000000
PIDS=()

cleanup() {
    echo
    echo "[RECOVERY] Stopping stress processes..."

    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null || true
    done

    wait 2>/dev/null || true
    echo "[RECOVERY] Cleanup complete."
}

trap cleanup EXIT INT TERM

echo "================================"
echo "       VM CHAOS LAB"
echo "================================"

echo "[INFO] CPU cores: $(nproc)"
echo "[INFO] RAM:"
free -h

echo "[START] Starting CPU stress..."

for ((i=1; i<=CPU_WORKERS; i++)); do
    timeout "$DURATION" bash -c '
        while true; do
            :
        done
    ' &
    PIDS+=("$!")
done

echo "[START] Starting bounded memory pressure..."

python3 - "$MEMORY_MB" "$DURATION" <<'PY' &
import sys
import time

size = int(sys.argv[1])
duration = int(sys.argv[2])

memory = bytearray(size * 1024 * 1024)

for i in range(0, len(memory), 4096):
    memory[i] = 1

print(f"[MEMORY] Allocated {size} MB", flush=True)
time.sleep(duration)
PY

PIDS+=("$!")

echo "[MONITOR] Experiment running for $DURATION seconds"

for ((i=0; i<DURATION; i+=5)); do
    echo "----- $(date) -----"
    uptime
    free -h
    sleep 5
done

echo "[DONE] Experiment finished"

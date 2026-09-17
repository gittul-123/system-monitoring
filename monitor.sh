#!/bin/bash

LOG_FILE="/var/log/agent-app/monitor.log"
PORT=15034

echo "====== SYSTEM MONITOR RESULT ======"

echo "[HEALTH CHECK]"

PID=$(pgrep -f "agent-app-linux-x86" | head -n 1)

if [ -z "$PID" ]; then
    echo "Checking process 'agent_app.py'. [FAIL]"
    exit 1
else
    echo "Checking process 'agent_app.py'. [OK] (PID: $PID)"
fi

if ss -tuln | grep -q ":$PORT"; then
    echo "Checking port $PORT. [OK]"
else
    echo "Checking port $PORT. [FAIL]"
    exit 1
fi

if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null)
    if [ -z "$UFW_STATUS" ]; then
        echo "[WARNING] Unable to verify UFW status (permission denied)"
    elif echo "$UFW_STATUS" | grep -q "Status: inactive"; then
        echo "[WARNING] UFW is inactive."
    fi
fi

echo
echo "[RESOURCE MONITORING]"

CPU=$(top -bn1 | awk '/Cpu/ {print 100-$8}')
MEM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
DISK=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

printf "CPU Usage : %.1f%%\n" "$CPU"
echo "MEM Usage : ${MEM}%"
echo "DISK Used : ${DISK}%"

CPU_INT=${CPU%.*}
MEM_INT=${MEM%.*}

if [ "$CPU_INT" -gt 20 ]; then
    echo "[WARNING] CPU threshold exceeded (${CPU}% > 20%)"
fi

if [ "$MEM_INT" -gt 10 ]; then
    echo "[WARNING] MEM threshold exceeded (${MEM}% > 10%)"
fi

if [ "$DISK" -gt 80 ]; then
    echo "[WARNING] DISK threshold exceeded (${DISK}% > 80%)"
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}% DISK_USED:${DISK}%" >> "$LOG_FILE"

echo
echo "[INFO] Log appended: $LOG_FILE"
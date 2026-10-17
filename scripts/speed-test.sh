#!/usr/bin/env bash

IF="wlp0s20f3"
SERVER="perf.he.net"
DURATION=10
STREAMS=4

RX="/sys/class/net/$IF/statistics/rx_bytes"
TX="/sys/class/net/$IF/statistics/tx_bytes"

mbps() {
    awk -v bytes="$1" -v ns="$2" \
        'BEGIN {
            printf "%.2f", (bytes * 8) / (ns / 1e9) / 1000000
        }'
}

echo "iperf3 benchmark"
echo "Interface: $IF"
echo "Server:    $SERVER"
echo

# DOWNLOAD
echo "↓ Testing download..."

RX1=$(cat "$RX")
T1=$(date +%s%N)

iperf3 \
    -c "$SERVER" \
    -R \
    -P "$STREAMS" \
    -t "$DURATION" \
    >/dev/null

T2=$(date +%s%N)
RX2=$(cat "$RX")

BYTES=$((RX2 - RX1))
DT=$((T2 - T1))

DOWNLOAD=$(mbps "$BYTES" "$DT")

printf "↓ Download: %s Mbps\n\n" "$DOWNLOAD"

sleep 2

# UPLOAD
echo "↑ Testing upload..."

TX1=$(cat "$TX")
T1=$(date +%s%N)

iperf3 \
    -c "$SERVER" \
    -P "$STREAMS" \
    -t "$DURATION" \
    >/dev/null

T2=$(date +%s%N)
TX2=$(cat "$TX")

BYTES=$((TX2 - TX1))
DT=$((T2 - T1))

UPLOAD=$(mbps "$BYTES" "$DT")

printf "↑ Upload:   %s Mbps\n" "$UPLOAD"

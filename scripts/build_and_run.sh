#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRIVER_DIR="$ROOT_DIR/driver"
APP_DIR="$ROOT_DIR/app"
OUTPUT_DIR="$ROOT_DIR/output"
OUTPUT_FILE="$OUTPUT_DIR/temperature_output.txt"

cd "$ROOT_DIR"

echo "=== Smart Temperature Monitor: build + demo ==="
echo "Kernel: $(uname -r)"

if [[ ! -e "/lib/modules/$(uname -r)/build" ]]; then
  echo "ERROR: matching Linux kernel headers are missing."
  echo "Run: sudo apt update && sudo apt install -y linux-headers-$(uname -r) build-essential g++ make git"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "[1/5] Building kernel driver..."
make -C "$DRIVER_DIR"

echo "[2/5] Loading kernel module..."
if lsmod | grep -q '^tempsensor'; then
  echo "tempsensor is already loaded."
else
  sudo insmod "$DRIVER_DIR/tempsensor.ko"
fi

if [[ ! -e /dev/tempsensor ]]; then
  echo "ERROR: /dev/tempsensor was not created."
  sudo dmesg | tail -30
  exit 1
fi

echo "[3/5] Building C++ application..."
g++ -Wall -Wextra -O2 -std=c++17 -o "$APP_DIR/temp_monitor" "$APP_DIR/temp_monitor.cpp"

echo "[4/5] Resetting sensor and setting demo drift..."
sudo "$APP_DIR/temp_monitor" --reset
sudo "$APP_DIR/temp_monitor" --drift 40

echo "[5/5] Starting monitor. Output will be saved to: $OUTPUT_FILE"
echo "Press Ctrl+C after you have demonstrated NORMAL/WARNING/CRITICAL."

trap 'echo; echo "Demo stopped. Output saved to: $OUTPUT_FILE"; exit 0' INT TERM
sudo "$APP_DIR/temp_monitor" --drift 40 | tee "$OUTPUT_FILE"

#!/usr/bin/env bash
set -euo pipefail

if lsmod | grep -q '^tempsensor'; then
  sudo rmmod tempsensor
  echo "tempsensor module unloaded."
else
  echo "tempsensor module is not loaded."
fi

sudo dmesg | tail -10 || true

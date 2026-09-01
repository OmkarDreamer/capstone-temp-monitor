#!/usr/bin/env bash
set -euo pipefail

echo "Installing Smart Temperature Monitor dependencies..."
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) g++ make git

echo
echo "Installed successfully."
echo "Kernel: $(uname -r)"
echo "Headers: /lib/modules/$(uname -r)/build"
